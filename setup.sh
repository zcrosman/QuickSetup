#!/usr/bin/env bash

# TODO
# - testing
# - more tools!
# - create aliases for common commands
# - automation of common repeatable tasks???


typeset -A bh_config
# If you want to use bloodhound integration with cme update the parameters below 
# If you want to remove this funcationality set the [bh_enabled] parameter to false
bh_config=(
    [bh_enabled]="True"
    [bh_uri]="127.0.0.1"
    [bh_port]="7687"
    [bh_user]="neo4j"       # CHANGE THIS
    [bh_pass]="password"    # CHANGE THIS
)


#PATHS
agressor_path='/home/'$SUDO_USER'/Documents/Agressor'
powershell_scripts='/opt/powershell'
tools_path='/opt'
win_source='/home/'$SUDO_USER'/Windows/Source'
win_compiled='/home/'$SUDO_USER'/Windows/Compiled'
# payload_mod = '/opt/payloadMod'   


check_user() {
if [ "$EUID" -ne 0 ]
    then echo -e "\nScript must be run with sudo\n"
    echo -e "sudo ./setup.sh"
    exit
fi
}

setup() {
    # Initial updates and installs
    apt update
    apt install -y python3-pip
}

install_go(){
    sudo apt install -y golang
    export GOROOT=/usr/lib/go
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
    source .bashrc
}

install_BOFs() {
    # Agressor Scripts Download
    echo -e "\n\n\n Installing agressor scripts\n\n\n"
    git clone https://github.com/trustedsec/CS-Situational-Awareness-BOF.git $agressor_path/CS-Situational-Awareness
    git clone https://github.com/rasta-mouse/Aggressor-Script.git $agressor_path/Rasta-agressor-scripts
    git clone https://github.com/Und3rf10w/Aggressor-scripts.git $agressor_path/Und3rf10w-agressor-scripts
    git clone https://github.com/harleyQu1nn/AggressorScripts $agressor_path/harleyQu1nn-agressor-scripts
    git clone https://github.com/anthemtotheego/CredBandit.git $agressor_path/CredBandit
    git clone https://github.com/mgeeky/cobalt-arsenal.git $agressor_path/cobalt-arsenal
    
    # TODO add custom BOFs
    # TODO load into Cobalt Strike
}

install_tools() {
    echo -e "\n\n\n Installing Kali tools\n\n\n"
    #Submime
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    apt-get -y install apt-transport-https
    apt-get update
    apt-get -y install sublime-text

    # mitm6
    git clone https://github.com/dirkjanm/mitm6.git $tools_path/mitm6
    pip3 install -r $tools_path/mitm6/requirements.txt
    python $tools_path/mitm6/setup.py install

    # PEASS
    # TODO - add PEASS binaries to binaries folder
    git clone https://github.com/carlospolop/PEASS-ng.git $tools_path/PEASS

    # Kerbrute
    go get github.com/ropnop/kerbrute #TODO output dir

    # pypykatz
    git clone https://github.com/skelsec/pypykatz.git $tools_path/pypykatz

    # evilwin-rm
    gem install evil-winrm

    # DonPAPI
    https://github.com/login-securite/DonPAPI.git $tools_path/DonPAPI
    python3 -m pip install $tools_path/DonPAPI/requirements.txt
    
    # Eyewitness
    git clone https://github.com/FortyNorthSecurity/EyeWitness.git $tools_path/EyeWitness
    cd $tools_path/EyeWitness/Python/setup
    ./setup.sh

    # Awuatone
    git clone https://github.com/michenriksen/aquatone.git $tools_path/aquatone
    cd $tools_path/aquatone
    ./build.sh

    # static linux binaries (build as needed)
    # this version of the script does not build each binary
    git clone https://github.com/andrew-d/static-binaries.git $tools_path/linux-static-binaries

    # Bloodhound and Neo4j install
    install_bh


    # Binary/Payload Modification/Creation
    # TODO - create folder for payload creation????
        # AVSignSeek (not payload creation, but used to detect where binary/paload is triggered in AV)
        git clone https://github.com/hegusung/AVSignSeek.git $tools_path/AVSignSeek

        # darkarmour
        git clone https://github.com/bats3c/darkarmour $tools_path/darkarmour
        apt -y install mingw-w64-tools mingw-w64-common g++-mingw-w64 gcc-mingw-w64 upx-ucl osslsigncode
        
        # ScareCrow
        git clone https://github.com/optiv/ScareCrow.git $tools_path/ScareCrow
        go get github.com/fatih/color
        go get github.com/yeka/zip
        go get github.com/josephspurrier/goversioninfo
        apt-get install -y openssl osslsigncode mingw-w64
        go build %tools_path/ScareCrow/ScareCrow.go
        
        # Donut
        pip3 install donut-shellcode

        # Ruler
        git clone https://github.com/sensepost/ruler.git $tools_path/ruler
        # TODO

        #Morph-HTA
        git clone https://github.com/vysecurity/morphHTA.git $tools_path/morphHTA

        # Invoke-Obfuscation
        git clone https://github.com/danielbohannon/Invoke-Obfuscation.git $tools_path/Invoke-Obfuscation

        # TODO - Go Payloads


        # TODO - add more!!!


# Powershell Tools
    #PowerSploit (PowerView, PowerUp, etc)
    git clone https://github.com/PowerShellMafia/PowerSploit.git $powershell_scripts/PowerSploit

    # MailSniper
    git clone https://github.com/dafthack/MailSniper.git $powershell_scripts/MailSniper

    # Nishang
    git clone https://github.com/samratashok/nishang.git $powershell_scripts/ninshang

    # PrivescCheck
    git clone https://github.com/itm4n/PrivescCheck.git $powershell/PrivescCheck
}

check_bh() {
    DIR=$tools_path'/BloodHound'
    echo $DIR
    if [ -d $tools_path'/BloodHound' ]
    then
        echo -e "BloodHound Already Installed...."
        start_bh
    else
        echo -e "BloodHound not installed"
        echo -e "Installing BloodHound and Neo4j"
        install_bh
        start_bh
    fi

}

install_bh() {
    # BloodHound
    mkdir $tools_path/BloodHound
    wget https://github.com/BloodHoundAD/BloodHound/releases/download/rolling/BloodHound-linux-x64.zip -O $tools_path/BloodHound/BloodHound_4.1.zip
    cd $tools_path/BloodHound
    unzip BloodHound_4.1.zip

    # # Configure cme intergration
    # if [ ${config[bh_enabled]} = 'True' ]
    #     crackmapexec # Run for initial setup of conf files
    #     $config='/home/'$SUDO_USER'/.cme/cme.conf'
    #     echo '\n[BloodHound]' >> $config
    #     echo 'bh_enabled = True' >> $config
    #     echo 'bh_uri = '${config[bh_uri]} >> $config
    #     echo 'bh_port = '${config[bh_port]} >> $config
    #     echo 'bh_user = '${config[bh_user]} >> $config
    #     echo 'bh_pass = '${config[bh_pass]} >> $config
    # fi

    # Neo4j
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
    echo 'deb https://debian.neo4j.com stable 4.0' > /etc/apt/sources.list.d/neo4j.list
    apt-get update
    apt-get install -y apt-transport-https neo4j
    systemctl stop neo4j
}


start_bh() {
    echo -e "Starting BloodHound!!!"
    cd $tools_path/BloodHound/BloodHound-linux-x64
    ./BloodHound --no-sandbox &
    
    # Add custom bloodhound queries from hausec (will need to refresh on first open)
    wget https://raw.githubusercontent.com/hausec/Bloodhound-Custom-Queries/master/customqueries.json -O '/home/'$SUDO_USER'/.config/bloodhound/customqueries.json'

    echo -e "Starting neo4j!!!"
    cd /usr/bin
    ./neo4j console 
    echo -e "Starting neo4j interface (firefox)!!!"
    runuser $(logname) -c "nohup firefox http://localhost:7474/browser/" &
}


win_source() {
    echo -e "\n\n\n Installing Windows tools (source)\n\n\n"
    # Rubeus
    git clone https://github.com/GhostPack/Rubeus.git $win_source/Rubeus

    # Seatbelt
    git clone https://github.com/GhostPack/Seatbelt.git $win_source/Seatbelt

    # SharpUp
    git clone https://github.com/GhostPack/SharpUp.git $win_source/SharpUpp

    # SharPersist
    git clone https://github.com/mandiant/SharPersist.git $win_source/SharPersist

    # LaZagne
    git clone https://github.com/AlessandroZ/LaZagne.git $win_source/lazagne


}

win_binaries(){
    echo -e "\n\n\n Installing Windows binaries\n\n\n"

    # SharPersist 1.0.1 (Jan 2020)
    wget https://github.com/mandiant/SharPersist/releases/download/v1.0.1/SharPersist.exe -O $win_compiled/SharPersist

    # LaZagne
    wget https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe -O $win_compiled/lazagne.exe

    # GhostPack Compiled
    git clone https://github.com/r3motecontrol/Ghostpack-CompiledBinaries.git $win_compiled/GhostPack

    # SharpHound
    wget https://github.com/BloodHoundAD/SharpHound/releases/download/v1.0.3/SharpHound-v1.0.3.zip -O $win_compiled/SharpHound/SharpHound.zip
    cd $win_compiled/SharpHound
    unzip SharpHound.zip

}

install_wl() {
    # install additional wordlists
    # TODO
    echo 'TODO'
}

add_aliases() {
    # nmap discovery
    # nmap detailed
    # parse
    # web scan
    alias discover
    alias hi='hi :)' # :)
    alias untar='tar -xf'
    alias www='python3 -m http.server 8080'
    alias ports='netstat -tulanp'


}

basic_scripts() {
    # TODO 
    echo 'TODO Create basic scirpts'
}


options () {
    clear
    echo -e "\n    Select an option from menu:"                      
    echo -e "\n Key  Menu Option:               Description:"
    echo -e " ---  ------------               ------------"
    echo -e "  1 - Basic Install              Run commands (3,4,5)" # TODO - organize the basic install 
    echo -e "  2 - Install All                Run all of the commands below (1-5)"    
    echo -e "  3 - Install Windows binaries   Install Windows binaries into " $win_compiled       
    echo -e "  4 - Install Windows source     Install Windows source into " $win_source                      
    echo -e "  5 - Install Kali tools         Install common Kali tools into " $tools_path  
    echo -e "  6 - Instal BOFs                Install Cobalt Strike agressor scripts into " $agressor_path                            
    echo -e "  7 - Start BloodHound           Start Neo4j and BloodHound (installs if not already installed)"
    echo -e "  8 - Install wordlists (TODO)   Install additional wordlists"
    echo -e "  8 - Add aliases (TODO)         TODO"
    echo -e "  9 - TODO                       TODO"
    echo -e "  x - Exit                       Exit the setup script"                                      

    read -n1 -p "\n  Press key for menu item selection or press X to exit: " menu

    case $menu in
        1) win_binaries;install_tools;install_BOFs
        2) setup;install_go;win_source;win_binaries;install_tools;install_BOFs;;
        3) win_source;;
        4) win_binaries;;
        5) install_tools;;
        6) install_BOFs;;
        7) check_bh;;
        9) install_wl;;
        9) add_aliases;;
        9) exit;;
        x) exit;;  
    esac

    #rerun menu?
}

# main
check_user
options
