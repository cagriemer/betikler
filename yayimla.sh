#!/bin/bash

ftp_yolu=/var/www/dergi_ftp/dergi/yayin/
sudo_yolu=/var/www/sudo/dergi/

sayi_bul()
{
sayi=`grep \# $ftp_yolu"yazi_listesi.txt" | cut -d"#" -f2`
}

kapak_olustur()
{
#ImageMagick bagimliligi var
/usr/bin/convert -density 600 $ftp_yolu"dergi.pdf[0]" -scale %15 $ftp_yolu"kapak.jpg"
cp $ftp_yolu"kapak.jpg" $sudo_yolu"kapak/"$cover
}

tarihlendir()
{
gun=`date +%d`

#Turkce karakter sorunu yasanmamasi icin
#ay sayisini %B ile almak yerine %m ile al
ay_sayi=`date +%m`

case "$ay_sayi" in
  01)	ay='Ocak';;
	02)	ay='Subat';;
	03)	ay='Mart';;
	04)	ay='Nisan';;
	05)	ay='Mayis';;
	06)	ay='Haziran';;
	07)	ay='Temmuz';;
	08)	ay='Agustos';;
	09)	ay='Eylul';;
	10)	ay='Ekim';;
	11)	ay='Kasim';;
	12)	ay='Aralik';;
esac

yil=`date +%Y`
}

paketle()
{
mv $ftp_yolu"dergi.pdf" $ftp_yolu$dergi_isim
cp $ftp_yolu$dergi_isim $sudo_yolu"paket/"$dergi_isim

if [ -d $ftp_yolu"ekler" ]
then
	zip -jr $sudo_yolu"paket/"$arsiv_isim $ftp_yolu$dergi_isim $ftp_yolu"ekler/" >/dev/null
else
	zip -jr $sudo_yolu"paket/"$arsiv_isim $ftp_yolu$dergi_isim > /dev/null
fi

pdf_boyut=`ls -alh $sudo_yolu"paket/"$dergi_isim | cut -d" " -f5`
arsiv_boyut=`ls -alh $sudo_yolu"paket/"$arsiv_isim | cut -d" " -f5`
}

arsiv_yukle()
{
tarih_degiskeni=$(php -r '$degiskenim = time(); echo $degiskenim;')
echo "INSERT INTO wp_dm_downloads" > arsiv_sql
echo "(name, icon, category, description, permissions, date, link, clicks)" >> arsiv_sql
echo "VALUES" >> arsiv_sql
echo \(\'$mysql_title"', 'winzip.gif', 1, '', 'yes', "$tarih_degiskeni", 'http://sudo.ubuntu-tr.net/dergi/paket/"$arsiv_isim"', 0)" >> arsiv_sql
mysql -u BURASIGIZLIDIR -pBURASIGIZLIDIR sudo < arsiv_sql
rm arsiv_sql
}

arsiv_id_al()
{
echo "SELECT * FROM wp_dm_downloads WHERE name='"$mysql_title"'" > arsiv_id_sql
mysql -u BURASIGIZLIDIR -pBURASIGIZLIDIR sudo < arsiv_id_sql > arsiv_id_cikti
arsiv_id=$(cat arsiv_id_cikti | grep ^[0-9] | awk '{print $1}')
rm arsiv_id_sql
rm arsiv_id_cikti
}

pdf_yukle()
{
tarih_degiskeni=$(php -r '$degiskenim = time(); echo $degiskenim;')
echo "INSERT INTO wp_dm_downloads" > pdf_sql
echo "(name, icon, category, description, permissions, date, link, clicks)" >> pdf_sql
echo "VALUES" >> pdf_sql
echo \(\'$mysql_title" PDF', 'pdf.gif', 1, '', 'yes', "$tarih_degiskeni", 'http://sudo.ubuntu-tr.net/dergi/paket/"$dergi_isim"', 0)" >> pdf_sql
mysql -u BURASIGIZLIDIR -pBURASIGIZLIDIR sudo < pdf_sql
rm pdf_sql
}

pdf_id_al()
{
echo "SELECT * FROM wp_dm_downloads WHERE name='"$mysql_title" PDF'" > pdf_id_sql
mysql -u BURASIGIZLIDIR -pBURASIGIZLIDIR sudo < pdf_id_sql > pdf_id_cikti
pdf_id=$(cat pdf_id_cikti | grep ^[0-9] | awk '{print $1}')
rm pdf_id_sql
rm pdf_id_cikti
}

sudo_yazi_olustur()
{
echo "<strong>"$title"</strong>" > metin.txt
echo "<img src=\"http://sudo.ubuntu-tr.net/dergi/kapak/"$cover"\" alt=\"\" width=\"400\" height=\"300\" />" >> metin.txt
echo "<br><br>" >> metin.txt
cat $ftp_yolu"yazi_listesi.txt" | (while read line; do echo "* "$line"<br><br>"; done) | grep -v "#" >> metin.txt
echo "<br><br>" >> metin.txt
echo "Arsiv dosyasini indirmek icin(.zip "$arsiv_boyut"):" >> metin.txt
echo "<br><br>[dm]"$arsiv_id"[/dm]" >> metin.txt
echo "<br><br>veya PDF olarak(.pdf "$pdf_boyut"):"  >> metin.txt
echo "<br><br>[dm]"$pdf_id"[/dm]" >> metin.txt
}

sudo_yazi_gonder()
{
#bsd-mailx bagimliligi var
/usr/bin/mailx -s $title BURASIGIZLIDIR@ubuntu-tr.net < metin.txt
/usr/bin/wget -O /dev/null http://sudo.ubuntu-tr.net/wp-content/plugins/postie/get_mail.php >/dev/null 2>&1
clear
echo "Blog duyurusu yapildi"
echo " "
rm metin.txt
}

forum_yazi_olustur()
{
echo "[b]"$title"[/b]" > metin.txt
echo " " >> metin.txt
echo " " >> metin.txt
echo "[img width=600 height=433]http://sudo.ubuntu-tr.net/dergi/kapak/"$cover"[/img]" >> metin.txt
echo " " >> metin.txt
cat $ftp_yolu"yazi_listesi.txt" | (while read line; do echo "* "$line; done) | grep -v "#" >> metin.txt
echo " " >> metin.txt
echo "Zip dosyasi olarak indirmek icin[url=http://sudo.ubuntu-tr.net/index.php?file_id="$arsiv_id"] buraya tiklayin[/url]." >> metin.txt
echo "PDF dosyasi olarak indirmek icin[url=http://sudo.ubuntu-tr.net/index.php?file_id="$pdf_id"] buraya tiklayin[/url]." >> metin.txt
echo "Google Docs uzerinden okumak icin[url=https://docs.google.com/viewer?url=sudo.ubuntu-tr.net/index.php?file_id="$pdf_id"] buraya tiklayin[/url]. " >> metin.txt
echo "Blog Sayfası icin [url=http://sudo.ubuntu-tr.net/sayilar/]buraya tiklayin[/url]." >> metin.txt
}

forum_yazi_gonder()
{
echo "================================================================"
echo " "
cat metin.txt
rm metin.txt
}

#dergi.pdf isimli dosyanin varligini kontrol et
if [ -f $ftp_yolu"dergi.pdf" ]
then

	read -p "Ozel sayi mi? (e/h): " OZEL_SAYI
	if [[ $OZEL_SAYI == "h" || $OZEL_SAYI == "hayir" ]]
	then
		sayi_bul

		name="sudo-sayi-"$sayi
		cover="sudo_"$sayi".jpg"
		title="Ubuntu Turkiye E-dergisi SUDO'nun "$sayi". Sayisi"
		mysql_title="Ubuntu TUrkiye E-dergisi SUDO\'nun "$sayi". Sayisi"

		kapak_olustur
		tarihlendir

		dergi_isim="sudo_"$gun"_"$ay"_"$yil"_sayi"$sayi".pdf"
		arsiv_isim="sudo_"$gun"_"$ay"_"$yil"_sayi"$sayi".zip"

		paketle
		arsiv_yukle
		arsiv_id_al
		pdf_yukle
		pdf_id_al
		sudo_yazi_olustur
		sudo_yazi_gonder
		forum_yazi_olustur
		forum_yazi_gonder

	else
		sayi_bul

		name="sudo-"$sayi"ozel-sayi"
		cover="sudo_"$sayi"_ozel_sayi.jpg"
		title="Ubuntu Turkiye E-dergisi SUDO'nun "$sayi" Ozel Sayisi"
		mysql_title="Ubuntu Turkiye E-dergisi SUDO\'nun "$sayi" Ozel Sayisi"

		kapak_olustur
		tarihlendir

		dergi_isim="sudo_"$gun"_"$ay"_"$yil"_"$sayi"_ozel_sayisi.pdf"
		arsiv_isim="sudo_"$gun"_"$ay"_"$yil"_"$sayi"_ozel_sayisi.zip"

		paketle
		arsiv_yukle
		arsiv_id_al
		pdf_yukle
		pdf_id_al
		sudo_yazi_olustur
		sudo_yazi_gonder
		forum_yazi_olustur
		forum_yazi_gonder

	fi
else
	echo " "
	echo "HATA! Yayin klasorunde dergi.pdf dosyasi bulunamadi."
	echo " "
fi
