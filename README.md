# jj-bump

A utility script for [Jujutsu (jj)](https://github.com/martinvonz/jj) that automatically moves bookmarks to the latest commit in the current working copy's lineage.

## What it does

`jj-bump` finds bookmarks in your commit history (ancestors of current working copy) and moves them forward to the most recent commit. This is useful when you've made changes on top of a bookmarked commit and want to move the bookmark to track your latest work.

### Example workflow

```bash
# Before: You have a bookmark on an older commit, and new commits on top
$ jj log
@  qnysrkto Refine implementation
◉  pqrmwxyz Add tests
◉  vulvkuvq <test-bookmark> Add new feature
◉  abcd1234 Initial commit

# Run jj-bump to move the bookmark forward to the latest commit
$ jj-bump
Moving bookmark 'test-bookmark' to commit qnysrkto...

# After: The bookmark now points to your latest commit
$ jj log
@  qnysrkto <test-bookmark> Refine implementation  ← bookmark moved here
◉  pqrmwxyz Add tests
◉  vulvkuvq Add new feature
◉  abcd1234 Initial commit
```

The script will:
1. Find all bookmarks in the ancestors of your current working copy (excluding the current commit)
2. Select the first bookmark found
3. Move it to the most recent commit in your working copy's lineage

**Note:** The script moves bookmarks to the last non-empty commit, automatically skipping over any empty commits in your history.

## Installation

### Using Nix Flakes

Run directly without installing:
```bash
nix run github:yourusername/jj-bump
```

Install to your profile:
```bash
nix profile install github:yourusername/jj-bump
```

Add to your `flake.nix`:
```nix
{
  inputs.jj-bump.url = "github:yourusername/jj-bump";
  
  # In your packages or home-manager:
  environment.systemPackages = [ inputs.jj-bump.packages.${system}.default ];
}
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/jj-bump
cd jj-bump

# Make the script executable
chmod +x jj_bump

# Copy to your PATH
cp jj_bump ~/.local/bin/jj-bump
```

## Requirements

- [Jujutsu (jj)](https://github.com/martinvonz/jj) - Version control system
- Bash

## Development

### Running tests

```bash
./test_jj_bump.sh
```

### Development shell

```bash
nix develop
```

## License

MIT
