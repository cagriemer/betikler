#!/bin/bash

# --- HAKKINDA ---
# SSH girisleri icin Google Authenticator ayarlarini yapan bir betik.
# Kodu googlecode'dan cekip, derliyor.
# Ardindan istemciler ve sunucu icin gerekli minimum ayarlari yapiyor. 

# --- BAGIMLILIKLAR ---
# make
# gcc
# libpam0g-dev
# libqrencode3 (elzem degil fakat terminalde QR kodu gosterebilmesi hos)

# --- CALISTIRMA ----
# Bir kere calistirildiktan sonra her SSH girisinde once Google Authenticator
# uygulamasinin urettigi bir seferlik sifreyi sordurur. Eger giris yapamiyorsaniz
# sunucunuzun ya da telefonunuzdaki uygulamanin zaman duzeltmelerini yapmanizi
# oneririm. Kullanmadan once mutlaka ssh localhost ile calistigina emin olun.

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


# Check dependencies
check_dependencies() {
echo -e "\nChecking dependencies\n"
## make
if [ "$(dpkg -l | awk '{print $2}' | grep -wc make)" -lt "1" ]
then echo -e "Installing make\n"; sudo apt-get install make && echo -e "make is successfully installed.\n"
else echo "make dependency is already satisfied."
fi
## gcc
if [ "$(dpkg -l | awk '{print $2}' | grep -wc gcc)" -lt "1" ]
then echo -e "Installing gcc...\n"; sudo apt-get install gcc && echo -e "gcc is successfully installed.\n"
else echo "gcc dependency is already satisfied."
fi
## libpam0g-dev
if [ "$(dpkg -l | awk '{print $2}' | grep -wc libpam0g-dev)" -lt "1" ]
then echo -e "Installing libpam0g-dev...\n"; sudo apt-get install libpam0g-dev && echo -e "libpam0g-dev is successfully installed.\n"
else echo -e "libpam0g-dev dependency is already satisfied."
fi
## libqrencode3
if [ "$(dpkg -l | awk '{print $2}' | grep -wc libqrencode3)" -lt "1" ]
then echo -e "Installing libqrencode3...\n"; sudo apt-get install libqrencode3 && echo -e "libqrencode3 is successfully installed.\n"
else echo -e "libqrencode3 dependency is already satisfied.\n"
fi
}

# Get the source code and compile
fetch_and_compile(){
if [ -e /usr/local/bin/google-authenticator ]
then echo -e "It looks like google-authenticator is already installed.\n"
else
wget https://google-authenticator.googlecode.com/files/libpam-google-authenticator-1.0-source.tar.bz2
tar xjvf libpam-google-authenticator-1.0-source.tar.bz2
cd libpam-google-authenticator-1.0
make
sudo make install
echo -e "google-authenticator is successfully installed.\n"
fi
}

# Client setup and file modifications
client_setup(){
## google-authenticator
if [ -e $HOME/.google_authenticator ]
then echo -e "There is a .google_authenticator file in your home directory."
echo -e "Please remove that file to run the configuration wizard again.\n"
else
/usr/local/bin/google-authenticator
fi
}
## /etc/pam.d/sshd
pamd_setup(){
if [ -e /etc/pam.d/sshd_backup_before_google_authenticator ]
then echo "Check your /etc/pam.d/ directory for sshd files."
echo -e "Someone -probably you- tried to install google-authenticator before.\n"
else
echo -e "I will add the following line \n"
echo -e "auth       required     pam_google_authenticator.so\n"
echo -e "to the beginning of this file.\n"
sudo mv /etc/pam.d/sshd /etc/pam.d/sshd_backup_before_google_authenticator
echo "auth       required     pam_google_authenticator.so" | sudo tee /etc/pam.d/sshd
cat /etc/pam.d/sshd_backup_before_google_authenticator | sudo tee -a /etc/pam.d/sshd
sudo chmod 644 /etc/pam.d/sshd
echo -e "You can always restore your original /etc/pam.d/sshd file from backup.\n"
fi
}
## /etc/ssh/sshd_config
sshd_setup(){
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
echo "You can revert back your sshd_config file by changing"
echo -e "ChallengeResponseAuthentication directive to no\n"
}

# Clean up
clean_up(){
rm -rf libpam-google*
}

# Restart services and enjoy
restart_service(){
sudo service ssh restart
echo -e "Enjoy\n"
}

# Main Script
check_dependencies
fetch_and_compile
client_setup
pamd_setup
sshd_setup
clean_up
restart_service
