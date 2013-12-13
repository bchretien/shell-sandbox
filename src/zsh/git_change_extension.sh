#!/bin/zsh
# Based on: http://stackoverflow.com/a/2989428/1043187

script_name=$(basename $0)
usage () {
  cat << EOF
  usage: $script_name -i ext_in -o ext_out [-d dir_name] [-v] [-r] [-n] [-h]

  This script changes the extension of Git files from ext_in to ext_out.

  OPTIONS:
     -h            Show this message
     -i            Input file extension
     -o            Ouput file extension
     -d            Directory
     -r            Recursive
     -n            Dry run (print changes without renaming files)
     -v            Verbose
EOF
}

dir_name="."
ext_in=""
ext_out=""
wrong_args=false
verbose=false
dry_run=false
recursive=false

OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "h?vrni:o:d:" opt; do
    case "$opt" in
       h|\?)     usage; exit 0;;
       n)        dry_run=true;;
       r)        recursive=true;;
       i)        ext_in=$OPTARG;;
       o)        ext_out=$OPTARG;;
       d)        dir_name=$OPTARG;;
       v)        verbose=true;;
    esac
done

if [ ! -d "$dir_name" ]; then
  echo "Error: the dir_name argument must be a directory (\"$dir_name\" set)."
  wrong_args=true
fi

if [[ -z "$ext_in" ]] || ! [[ "$ext_in" =~ ^[a-zA-Z][a-zA-Z_\.]*[a-zA-Z]$ ]] ; then
  echo "Error: you must specify a valid (starting/ending with a letter)" \
       "source file extension with -i (\"$ext_in\" set)."
  wrong_args=true
fi

if [[ -z "$ext_out" ]] || ! [[ "$ext_out" =~ ^[a-zA-Z][a-zA-Z_\.]*[a-zA-Z]$ ]] ; then
  echo "Error: you must specify a valid (starting/ending with a letter)" \
        "destination file extension with -o (\"$ext_out\" set)."
  wrong_args=true
fi

if $wrong_args ; then
  exit 1
fi

# strip any trailing slash from the dir_name value
dir_name="${dir_name%/}"

if $verbose ; then
  print -n 'Renaming Git files *.'${ext_in}' to *.'${ext_out}' in '${dir_name}
  if $recursive ; then
    print -n ' (recursively)'
  fi

  if $dry_run ; then
    print -n ' (dry run)'
  fi
  print
fi

# The actual useful command
if $verbose; then
  if $recursive; then
    zsh -c 'autoload zmv && $0 $@' zmv -nfp git -o 'mv ' ${dir_name}'/(**/)(*).'${ext_in} ${dir_name}'/${1}${2}'.${ext_out}
  else
    zsh -c 'autoload zmv && $0 $@' zmv -nfp git -o 'mv ' ${dir_name}'/(*).'${ext_in} ${dir_name}'/${1}'.${ext_out}
  fi
fi

if ! $dry_run ; then
  if $recursive; then
    zsh -c 'autoload zmv && $0 $@' zmv -fp git -o 'mv ' ${dir_name}'/(**/)(*).'${ext_in} ${dir_name}'/${1}${2}'.${ext_out}
  else
    zsh -c 'autoload zmv && $0 $@' zmv -fp git -o 'mv ' ${dir_name}'/(*).'${ext_in} ${dir_name}'/${1}'.${ext_out}
  fi
fi
