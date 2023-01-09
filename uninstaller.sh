gb=$'\e[42m\e[30m'
reset=$'\e[0m'
up=$'\e[1F'
clear=$'\e[K'
newline=$'\n'

alias echo-prog='progressbar $count $total'

repeat() {
  yes $1 |
  head -n $2 |
  tr -d $'\n'
}

progressbar() {
  count=$1
  total=$2
  message="$3"

  percent_int=$(((count*100)/total))

  bar_width=$(($COLUMNS-7))
  bar_body_length=$((bar_width*percent_int/100))

  if [ $percent_int != 0 ]
  then
    bar_body=`repeat "#" $bar_body_length`
  fi

  bar_space=`repeat "." $((bar_width-bar_body_length))`
  percent="  $percent_int"

  bar="$gb"
  bar+="${percent: -3:3}"
  bar+="%"
  bar+="$reset"
  bar+=" ["
  bar+="$bar_body"
  bar+="$bar_space"
  bar+="]"

  shift 2
  echo $@

  echo $clear$newline
  echo -n "$bar"
  echo -n "$up"
}

function deleter() {
  packages=`pm list packages|
            cut -d ':' -f 2|
            grep $carrier_exp|
            grep -v $ignore_exp`
  count=0
  total=`echo "$packages"|
         wc -l`

  for package in $packages
  do
    echo-prog Uninstalling $package ...
    if [ $dry_run != true ]
    then
      if [ $humanity_check == true ]
      then
        echo-prog "[Y/n] "
        read check
        echo-prog -n
        if [ "$check" == n -o "$check" == N ]
        then
          echo-prog 無視します
          count=$((count+1))
          continue
        fi
      fi
      echo-prog `pm uninstall --user 0 $package`
    fi
    count=$((count+1))
    echo-prog
  done

  echo
  echo 完了$clear
}

function parse-args() {
  carrier_exp=""
  ignore_exp="-e 🏢☠️ "
  humanity_check=false
  dry_run=false
  script_path=$0
  while [ "$1" != "" ]
  do
    case $1 in
      -h| --help)
        echo "Carrier App Uninstaller"
        echo "キャリアアプリを削除します"
        echo "Usage: $script_path [-c CARRIER] [-i APP] [-d] [-h]"
        echo "  -c, --carrier CARRIER  削除したいアプリのキャリアを直接指定します"
        echo "                         複数指定可"
        echo "  -i, --ignore APP       削除しないアプリのIDを指定します"
        echo "                         ヤバそうな気がしたアプリを指定しといてください"
        echo "                         複数指定可"
        echo "  -C, --humanity-check   一つ一つ確認しながら削除します"
        echo "                         想像に難く無いとは思いますがクソほど面倒です"
        echo "  -d, --dry-run          実際に削除はせずシミュレーションします"
        echo "  -h, --help             このメッセージを表示します"
        exit 0;;
      -c| --carrier)
        shift
        carrier_exp+="-e $1 ";;
      -i| --ignore)
        shift
        ignore_exp+="-e $1 ";;
      -C| --humanity-check)
        humanity_check=true;;
      -d| --dry-run)
        dry_run=true;;
      *)
        echo "Error: 不正な引数です: $1"
        exit 1;;
    esac
    shift
  done
}

function choose-carrier() {
  echo "どのキャリアのアプリを削除しますか？"
  echo "1) au"
  echo "2) NTT Docomo"
  echo "3) Softbank"
  echo "4) Rakuten Mobile"
  echo "5) 全部"
  echo -n "> "
  read num
  case $num in
    1)
      carrier_exp="-e kddi -e auone";;
    2)
      carrier_exp="-e docomo -e ntt";;
    3)
      carrier_exp="-e softbank";;
    4)
      carrier_exp="-e rakuten";;
    5)
      carrier_exp="-e 'docomo' -e 'ntt' -e 'auone' -e 'rakuten' -e 'kddi' -e 'softbank'";;
    *)
      echo "1-5までの数値を指定してください"
      exit 0;;
  esac
}

function install-script() {
  adb push $0 /data/data/com.android.shell/cache/
  adb shell sh /data/data/com.android.shell/cache/$0 $@
  adb shell rm /data/data/com.android.shell/cache/$0
}

function main() {
  if [ -e /system/bin/sh -a `whoami` == shell ]
  then
    parse-args $@

    if [ "$carrier_exp" == "" ]
    then
      choose-carrier
    else
      echo "IDに[`echo -n $carrier_exp| sed 's/-e/ /'`]が含まれるアプリを削除します"
    fi

    deleter
  else
    install-script $@
  fi
}

main $@
