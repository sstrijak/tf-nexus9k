sudo apt-get install xinetd tftpd tftp
sudo nano /etc/xinetd.d/tftp
sudo mkdir /tftpboot
sudo chmod -R 777 /tftpboot
sudo chown -R nobody /tftpboot
sudo useradd tftpboot -p xxx
sudo mkdir /home/tftpboot
sudo chown tftpboot /home/tftpboot/
sudo chgrp tftpboot /home/tftpboot/
sudo chmod go-wrx /home/tftpboot/

