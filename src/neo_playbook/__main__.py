"""Entry point for ``python -m neo_playbook <command>``."""

import sys


def _parse_roms_arg() -> list[str] | None:
    """Extract --roms value from argv."""
    for arg in sys.argv:
        if arg.startswith("--roms="):
            return [r.strip() for r in arg.split("=", 1)[1].split(",") if r.strip()]
        if arg == "--roms":
            idx = sys.argv.index(arg)
            if idx + 1 < len(sys.argv):
                return [r.strip() for r in sys.argv[idx + 1].split(",") if r.strip()]
    return None


def main():
    usage = "Usage: uv run python -m neo_playbook {fetch|render|sync|sync-moves|sync-dips}"

    if len(sys.argv) < 2:
        print(usage)
        sys.exit(1)

    command = sys.argv[1]
    force = "--force" in sys.argv

    if command == "fetch":
        from neo_playbook.fetch import main as fetch_main
        fetch_main()
    elif command == "render":
        from neo_playbook.render import main as render_main
        render_main()
    elif command == "sync":
        from neo_playbook.firebase_sync import main as sync_main
        sync_main(force=force)
    elif command == "sync-moves":
        from neo_playbook.command_sync import main as sync_moves_main
        roms = _parse_roms_arg()
        use_all = "--all" in sys.argv
        if not roms and not use_all:
            print("Usage: uv run python -m neo_playbook sync-moves --roms kof94,samsho [--force]")
            print("       uv run python -m neo_playbook sync-moves --all [--force]")
            sys.exit(1)
        sync_moves_main(rom_names=roms, all_roms=use_all, force=force)
    elif command == "sync-dips":
        from neo_playbook.dip_sync import main as sync_dips_main
        roms = _parse_roms_arg()
        use_all = "--all" in sys.argv
        if not roms and not use_all:
            print("Usage: uv run python -m neo_playbook sync-dips --roms 2020bb,kof94 [--force]")
            print("       uv run python -m neo_playbook sync-dips --all [--force]")
            sys.exit(1)
        sync_dips_main(rom_names=roms, all_roms=use_all, force=force)
    else:
        print(f"Unknown command: {command}")
        print(usage)
        sys.exit(1)


if __name__ == "__main__":
    main()
