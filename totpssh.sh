#!/bin/bash

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
