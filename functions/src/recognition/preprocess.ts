/**
 * Image preprocessing with `sharp` before sending to OpenAI.
 *
 *  - normalize EXIF orientation
 *  - resize the full image to <= 2048 px on its longest side
 *  - produce a contrast/sharpened variant tuned for label legibility
 *  - emit horizontal or vertical slice crops when the photo's aspect
 *    ratio strongly suggests multiple objects (shelf rows / spine stacks)
 *
 * The original uploaded image is never modified — it stays in Storage
 * untouched. We only return derived buffers in memory.
 */

type SharpPipeline = {
  metadata: () => Promise<{ width?: number; height?: number; orientation?: number | null }>;
  rotate: () => SharpPipeline;
  resize: (options: Record<string, unknown>) => SharpPipeline;
  modulate: (options: Record<string, unknown>) => SharpPipeline;
  normalise: () => SharpPipeline;
  sharpen: (options: Record<string, unknown>) => SharpPipeline;
  extract: (options: Record<string, unknown>) => SharpPipeline;
  jpeg: (options: Record<string, unknown>) => {
    toBuffer: (options?: Record<string, unknown>) => Promise<{ data: Buffer; info: { width: number; height: number } }>;
  };
};

type SharpFactory = {
  (input?: Buffer | string, options?: Record<string, unknown>): SharpPipeline;
  (options?: Record<string, unknown>): SharpPipeline;
};

const getSharp = (): SharpFactory => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  return require("sharp") as SharpFactory;
};

export type PreparedImage = {
  buffer: Buffer;
  mimeType: string;
  width: number;
  height: number;
};

export type CropStrategy = "none" | "horizontal_shelf" | "vertical_spines";

export type PreprocessMetadata = {
  originalWidth: number;
  originalHeight: number;
  orientation: number | null;
  cropStrategy: CropStrategy;
  cropCount: number;
};

export type PreprocessResult = {
  full: PreparedImage;
  sharpened: PreparedImage;
  crops: PreparedImage[];
  metadata: PreprocessMetadata;
};

const MAX_DIMENSION = 2048;
const SHARPEN_DIMENSION = 1600;
const CROP_DIMENSION = 1024;

const SHARP_INIT = { failOn: "none" as const };

async function toPreparedJpeg(
  pipeline: SharpPipeline,
  quality: number,
): Promise<PreparedImage> {
  const out = await pipeline.jpeg({ quality }).toBuffer({ resolveWithObject: true });
  return {
    buffer: out.data,
    mimeType: "image/jpeg",
    width: out.info.width,
    height: out.info.height,
  };
}

export async function preprocessImage(input: Buffer): Promise<PreprocessResult> {
  const sharp = getSharp();
  const meta = await sharp(input, SHARP_INIT).metadata();
  const origW = meta.width ?? 0;
  const origH = meta.height ?? 0;

  const full = await toPreparedJpeg(
    sharp(input, SHARP_INIT)
      .rotate()
      .resize({
        width: MAX_DIMENSION,
        height: MAX_DIMENSION,
        fit: "inside",
        withoutEnlargement: true,
      }),
    88,
  );

  const sharpened = await toPreparedJpeg(
    sharp(input, SHARP_INIT)
      .rotate()
      .resize({
        width: SHARPEN_DIMENSION,
        height: SHARPEN_DIMENSION,
        fit: "inside",
        withoutEnlargement: true,
      })
      .modulate({ saturation: 0.9 })
      .normalise()
      .sharpen({ sigma: 1.0 }),
    92,
  );

  const crops: PreparedImage[] = [];
  let cropStrategy: CropStrategy = "none";

  if (origW > 0 && origH > 0) {
    const aspect = origW / origH;

    if (aspect >= 2.0) {
      cropStrategy = "horizontal_shelf";
      const slices = Math.min(4, Math.max(2, Math.round(aspect)));
      const sliceWidth = Math.floor(origW / slices);
      for (let i = 0; i < slices; i++) {
        const left = i * sliceWidth;
        const width = i === slices - 1 ? origW - left : sliceWidth;
        crops.push(
          await toPreparedJpeg(
            sharp(input, SHARP_INIT)
              .rotate()
              .extract({ left, top: 0, width, height: origH })
              .resize({
                width: CROP_DIMENSION,
                height: CROP_DIMENSION,
                fit: "inside",
                withoutEnlargement: true,
              })
              .sharpen({ sigma: 0.8 }),
            88,
          ),
        );
      }
    } else if (aspect <= 0.5) {
      cropStrategy = "vertical_spines";
      const slices = Math.min(4, Math.max(2, Math.round(origH / origW)));
      const sliceHeight = Math.floor(origH / slices);
      for (let i = 0; i < slices; i++) {
        const top = i * sliceHeight;
        const height = i === slices - 1 ? origH - top : sliceHeight;
        crops.push(
          await toPreparedJpeg(
            sharp(input, SHARP_INIT)
              .rotate()
              .extract({ left: 0, top, width: origW, height })
              .resize({
                width: CROP_DIMENSION,
                height: CROP_DIMENSION,
                fit: "inside",
                withoutEnlargement: true,
              })
              .sharpen({ sigma: 0.8 }),
            88,
          ),
        );
      }
    }
  }

  return {
    full,
    sharpened,
    crops,
    metadata: {
      originalWidth: origW,
      originalHeight: origH,
      orientation: meta.orientation ?? null,
      cropStrategy,
      cropCount: crops.length,
    },
  };
}
