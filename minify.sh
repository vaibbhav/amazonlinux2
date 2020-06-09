#!/bin/bash

run_install() {
  read -r -p "${1:-Do you want to install missing libraries? [y/N]} " response
  case "$response" in
  [yY][eE][sS] | [yY])
    sudo apt-get install ${installpackage[@]}
    echo -e "\e[1m\e[32mLibraries installed.\e[0m"
    ;;
  *)
    echo " "
    echo -e "\e[1m \e[91m yui compressor required to perform the operation.\e[21m \e[0m"
    echo " "
    exit
    ;;
  esac
}
installpackage=("yui-compressor")
dpkg -s "${installpackage[@]}" >/dev/null 2>&1 || run_install

echo " "
read -r -p "Enter Directory path to perform operation:  " fileresponse
echo " "
read -p "Want to change file name and generate with *.min.js ? [Y/n]: " answer

if [ "$answer" != "${answer#[Yy]}" ]; then
  FILETYPE=".min.js"
else
  echo "Minify file will be replace with original file name"
  FILETYPE=".js"
fi
echo " "
echo "***********************************************************************"
FILES=$(find $fileresponse -type f -name '*.js')
for file in $FILES; do
  if [[ $file != *.spec.js && $file != *.min.js ]]; then
    #echo $file
    filename=$(basename -s .js "$file")"$FILETYPE"
    DIR=$(dirname "${file}")
    #echo $file
    echo "${DIR}/"$filename
    yui-compressor $file >"${DIR}/"$filename
  fi
done

read -p "Do you want css minification ? [Y/n]: " cssanswer
if [ "$cssanswer" != "${cssanswer#[Yy]}" ]; then
  echo -e "\e[1m\e[32m================"
  echo -e "\e[1m\e[32m|| Continue... ||"
  echo -e "\e[1m\e[32m================\e[0m"
else
  echo -e "\e[1m\e[91m================"
  echo -e "\e[1m\e[91m|| Exiting... ||"
  echo -e "\e[1m\e[91m================\e[0m"
  exit
fi

read -p "Want to change file name and generate with *.min.css ? [Y/n]: " ynanswer
if [ "$ynanswer" != "${ynanswer#[Yy]}" ]; then
  FILETYPECSS=".min.css"
else
  echo "Minify file will be replace with original file name"
  FILETYPECSS=".css"
fi
echo " "
echo "***********************************************************************"
FILES=$(find $fileresponse -type f -name '*.css')
for file in $FILES; do
  if [[ $file != *.spec.css && $file != *.min.css ]]; then
    #echo $file
    filename=$(basename -s .css "$file")"$FILETYPECSS"
    DIR=$(dirname "${file}")
    #echo $file
    echo "${DIR}/"$filename
    yui-compressor $file >"${DIR}/"$filename
  fi
done
echo " "
echo -e "\e[1m\e[32m****************************************************************************\e[0m"
echo -e "\e[1m\e[32m**                             "
echo -e "\e[1m\e[32m**  Operation completed check DIR \e[21m\e[0m>  "$fileresponse
echo -e "\e[1m\e[32m**                             "
echo -e "\e[1m\e[32m****************************************************************************\e[0m"
