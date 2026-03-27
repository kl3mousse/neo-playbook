"""Entry point for ``python -m neo_playbook <command>``."""

import sys


def main():
    usage = "Usage: uv run python -m neo_playbook {fetch|render}"

    if len(sys.argv) < 2:
        print(usage)
        sys.exit(1)

    command = sys.argv[1]

    if command == "fetch":
        from neo_playbook.fetch import main as fetch_main
        fetch_main()
    elif command == "render":
        from neo_playbook.render import main as render_main
        render_main()
    else:
        print(f"Unknown command: {command}")
        print(usage)
        sys.exit(1)


if __name__ == "__main__":
    main()
