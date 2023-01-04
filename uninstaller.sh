function build-script() {
  echo "carrier_exp='$carrier_exp'"
  echo "dry_run=$dry_run"
  cat $script_path
}

if [ -e /system/bin/sh -a `whoami` == shell ]
then
  pm list packages|
    cut -d ':' -f 2|
      grep $carrier_exp|
        while read package
        do
          echo Uninstalling $package ...
          if [ $dry_run != true ]
          then
            pm uninstall --user 0 $package
          fi
          echo
        done
  echo 完了
else
  #-e 'docomo' -e 'ntt' -e 'auone' -e 'rakuten' -e 'kddi' -e 'softbank'
  carrier_exp=""
  dry_run=false
  script_path=$0
  while [ "$1" != "" ]
  do
    case $1 in
      -h| --help)
        echo "Carrier App Uninstaller"
        echo "キャリアアプリを削除します"
        echo "Usage: $script_path [-c CARRIER] [-d] [-h]"
        echo "  -c, --carrier CARRIER  削除したいアプリのキャリアを直接指定します"
        echo "                         複数指定可"
        echo "  -d, --dry-run          実際に削除はせずシミュレーションします"
        echo "  -h, --help             このメッセージを表示します"
        exit 0;;
      -c| --carrier)
        shift
        carrier_exp+="-e $1 ";;
      -d| --dry-run)
        dry_run=true;;
      *)
        echo "Error: 不正な引数です: $1"
        exit 1;;
    esac
    shift
  done
  if [ "$carrier_exp" == "" ]
  then
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
  fi
  echo "実行します"
  build-script|
    adb shell
fi
