#!/bin/bash

# --- HAKKINDA ---
# Ubuntu Turkiye e-dergisi SUDO'yu yayima alan betik
# Editor yayimlanabilir onayi verdikten sonra tasarimcilarin
# ve yazarlarin kullandigi ftp dizininden dergiyi alip
# yeniden adlandirdiktan sonra disari acik web dizinlerine
# kopyalar ve ftp alanindaki yazi_listesi.txt dosyasindan
# duyuru metinini olusturur. Postie plugin'i sayesinde
# duyuruyu otomatik olarak WordPress temelli dergi blogunda 
# yayinlar. Foruma gecilecek duyuruyu ise terminal ekranina basar. 

# --- BAGIMLILIKLAR ---
# imagemagick (.pdf dosyasindan duyuru icin kapak sayfasinin imajini cikariyor)
# bsd-mailx (postie'ye duyuru metinini gondermek icin gerekli)

# --- CALISTIRMA ----
# dergiyayimlama dizinine gecilip ./yayimla.sh komutunun verilmesi yeterlidir.
# SUDO'nun bloguna yaziyi 10 dakikalik bir gecikme ile otomatik olarak koyar.
# Forum duyurusunu ise terminal ekranina basar.

# --- LISANS ---
# Kisaca; 3 maddeli BSD Lisansi
# Uzunca su sekilde; 

# Copyright (c) 2013, Ubuntu Turkiye
# All rigts reserved.

# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.

# Neither the name of the Ubuntu Turkiye nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

# --- ILETISIM ---
# http://forum.ubuntu-tr.net

ftp_yolu=
sudo_yolu=

mysql_kullanicisi=
mysql_sifresi=
mysql_veritabani=

kapak_boy=600
kapak_en=433

wp_eposta=

# Dergi sayisini bulan fonksiyon. yazi_listesi.txt isimli belgede tek bir # olmalidir
sayi_bul()
{
	sayi=$(grep \# $ftp_yolu"yazi_listesi.txt" | cut -d"#" -f2)
}

# Derginin kapagini PDF dosyasindan alan ve ilgili yere kopyalayan fonksiyon
# ImageMagick bagimliligi var
kapak_olustur()
{
	/usr/bin/convert -density 600 $ftp_yolu"dergi.pdf[0]" -scale %15 $ftp_yolu"kapak.jpg"
	cp $ftp_yolu"kapak.jpg" $sudo_yolu"kapak/"$cover
}

tarihlendir()
{
	gun=$(date +%d)

	#Turkce karakter sorunu yasanmamasi icin
	#ay sayisini %B ile almak yerine %m ile al
	ay_sayi=$(date +%m)

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

	yil=$(date +%Y)
}

paketle()
{
	mv $ftp_yolu"dergi.pdf" $ftp_yolu$dergi_isim
	cp $ftp_yolu$dergi_isim $sudo_yolu"paket/"$dergi_isim

	if [ -d $ftp_yolu"ekler" ]
	then
		zip -jr $sudo_yolu"paket/"$arsiv_isim $ftp_yolu$dergi_isim $ftp_yolu"ekler/" > /dev/null
	else
		zip -jr $sudo_yolu"paket/"$arsiv_isim $ftp_yolu$dergi_isim > /dev/null
	fi	

	pdf_boyut=$(ls -alh $sudo_yolu"paket/"$dergi_isim | cut -d" " -f5)
	arsiv_boyut=$(ls -alh $sudo_yolu"paket/"$arsiv_isim | cut -d" " -f5)	
}

arsiv_yukle()
{
	tarih_degiskeni=$(php -r '$degiskenim = time(); echo $degiskenim;')
	echo "INSERT INTO wp_dm_downloads" > arsiv_sql
	echo "(name, icon, category, description, permissions, date, link, clicks)" >> arsiv_sql
	echo "VALUES" >> arsiv_sql
	echo \(\'$mysql_title"', 'winzip.gif', 1, '', 'yes', "$tarih_degiskeni", 'http://sudo.ubuntu-tr.net/dergi/paket/"$arsiv_isim"', 0)" >> arsiv_sql
	mysql -u $mysql_kullanicisi -p$mysql_sifresi $mysql_veritabani < arsiv_sql
	rm arsiv_sql
}

arsiv_id_al()
{
	echo "SELECT * FROM wp_dm_downloads WHERE name='"$mysql_title"'" > arsiv_id_sql
	mysql -u $mysql_kullanicisi -p$mysql_sifresi $mysql_veritabani < arsiv_id_sql > arsiv_id_cikti
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
	mysql -u $mysql_kullanicisi -p$mysql_sifresi $mysql_veritabani < pdf_sql
	rm pdf_sql
}

pdf_id_al()
{
	echo "SELECT * FROM wp_dm_downloads WHERE name='"$mysql_title" PDF'" > pdf_id_sql
	mysql -u $mysql_kullanicisi -p$mysql_sifresi $mysql_veritabani < pdf_id_sql > pdf_id_cikti
	pdf_id=$(cat pdf_id_cikti | grep ^[0-9] | awk '{print $1}')
	rm pdf_id_sql
	rm pdf_id_cikti
}

sudo_yazi_olustur()
{
	echo "<strong>"$title"</strong>" > metin.txt
	echo "<img src=\"http://sudo.ubuntu-tr.net/dergi/kapak/"$cover"\" alt=\"\" width=\""$kapak_en"\" height=\""$kapak_boy"\" />" >> metin.txt
	echo "<br><br>" >> metin.txt
	cat $ftp_yolu"yazi_listesi.txt" | (while read line; do echo "* "$line"<br><br>"; done) | grep -v "#" >> metin.txt
	echo "<br><br>" >> metin.txt
	echo "Arsiv dosyasini indirmek icin(.zip "$arsiv_boyut"):" >> metin.txt
	echo "<br><br>[dm]"$arsiv_id"[/dm]" >> metin.txt
	echo "<br><br>veya PDF olarak(.pdf "$pdf_boyut"):" >> metin.txt
	echo "<br><br>[dm]"$pdf_id"[/dm]" >> metin.txt
	sudo_tags=$name", "$title
	echo "<br><br>tags: "$sudo_tags >> metin.txt
}

#bsd-mailx bagimliligi var
sudo_yazi_gonder()
{
	/usr/bin/mailx -s $title $wp_eposta < metin.txt
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
	echo "[img width="$kapak_en" height="$kapak_boy"]http://sudo.ubuntu-tr.net/dergi/kapak/"$cover"[/img]" >> metin.txt
	echo " " >> metin.txt
	cat $ftp_yolu"yazi_listesi.txt" | (while read line; do echo "* "$line; done) | grep -v "#" >> metin.txt
	echo " " >> metin.txt
	echo "Zip dosyasi olarak indirmek icin[url=http://sudo.ubuntu-tr.net/index.php?file_id="$arsiv_id"] buraya tiklayin[/url]." >> metin.txt
	echo "PDF dosyasi olarak indirmek icin[url=http://sudo.ubuntu-tr.net/index.php?file_id="$pdf_id"] buraya tiklayin[/url]." >> metin.txt
	echo "Google Docs uzerinden okumak icin[url=https://docs.google.com/viewer?url=sudo.ubuntu-tr.net/index.php?file_id="$pdf_id"] buraya tiklayin[/url]. " >> metin.txt
	echo "Blog Sayfasi icin [url=http://sudo.ubuntu-tr.net/sudo/sayilar/]buraya tiklayin[/url]." >> metin.txt
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
		mysql_title="Ubuntu Turkiye E-dergisi SUDO\'nun "$sayi". Sayisi"

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
