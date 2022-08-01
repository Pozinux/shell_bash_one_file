#!/bin/bash
# Description : script de mise en place des PS1 sur les terminaux de PROD pour les differencier du  reste
#############################################################################################################

echo
hostname
date
echo

echo "Etape 1 : Intégration du PS1 dans /etc/profile.d/custom_PROD.sh"
PROFILE_SCRIPT="/etc/profile.d/custom_PROD.sh"
echo " creation du script : ${PROFILE_SCRIPT} "


cat << EOF > ${PROFILE_SCRIPT}
ROUGE_SURLIGNE_BASH="\[\e[7;1;31m\]"
ROUGE_BASH="\[\e[0;31m\]"
RESET_COLOR_BASH="\[\e[0;0m\]"
ROUGE_SURLIGNE_KSH='\033[7;31m'
ROUGE_KSH='\033[0;31m'
RESET_COLOR_KSH='\033[0;0m'

if [ \$SHELL == "/bin/ksh" ]
then
        export PS1="\$(printf "\${ROUGE_SURLIGNE_KSH}%s\${RESET_COLOR_KSH} \${ROUGE_KSH}%s[\$LOGNAME@\`hostname\` \\\$PWD]$ %s\${RESET_COLOR_KSH}" "PROD")"
fi

if [ \$SHELL ==  "/bin/bash" -a \$LOGNAME != "root" ]
then
        export PROMPT_COMMAND='export PS1="\${ROUGE_SURLIGNE_BASH}PROD\${ROUGE_BASH} [\u@\h \W]$ \${RESET_COLOR_BASH}"'
fi

if [ \$LOGNAME == "root" ]
then
        export PROMPT_COMMAND='export PS1="\${ROUGE_SURLIGNE_BASH}PROD\${ROUGE_BASH} [\u@\h \W]# \${RESET_COLOR_BASH}"'
fi
EOF

chmod 644 ${PROFILE_SCRIPT}


echo "Etape 2 : Mettre en commentaire les PS1 pour les user ksh"
for USERKSH in $(grep ksh /etc/passwd| cut -d":" -f 1)
do
        echo "User trouvé : $USERKSH"
        PROFILE_DIR=`grep "\<$USERKSH\>" /etc/passwd | grep ksh | cut -d":" -f 6`
        echo $PROFILE_DIR
        TEXT_DEL="PS1="
		TEXT_DEL_2="export PS1="
        PROFILE_FILE="${PROFILE_DIR}/.profile"
        echo $PROFILE_FILE
        if [ -e ${PROFILE_FILE} ]
        then
		cp ${PROFILE_FILE} ${PROFILE_FILE}_save_$(date +%Y%m%d%H%M%S)
                echo "Remplacement en cours..."
                sed -i  "s/^\(${TEXT_DEL}*\)/#\1/g"  "${PROFILE_FILE}"
		sed -i  "s/^\(${TEXT_DEL_2}*\)/#\1/g"  "${PROFILE_FILE}"
        fi
done


echo "Etape 3 : Mettre en commentaire les PS1 pour les user bash"
for USERBASH in $(grep bash /etc/passwd| cut -d":" -f 1)
do
        echo "User trouvé : $USERBASH"
        PROFILE_DIR=`grep "\<$USERBASH\>" /etc/passwd| grep bash | cut -d":" -f 6`
        echo $PROFILE_DIR
        TEXT_DEL="PS1="
		TEXT_DEL_2="export PS1="	
        PROFILE_FILE="${PROFILE_DIR}/.bash_profile"
        echo $PROFILE_FILE
        if [ -e ${PROFILE_FILE} ]
        then                
		cp ${PROFILE_FILE} ${PROFILE_FILE}_save_$(date +%Y%m%d%H%M%S)	
		echo "Remplacement en cours..." 
		sed -i  "s/^\(${TEXT_DEL}*\)/#\1/g" "${PROFILE_FILE}"
		sed -i  "s/^\(${TEXT_DEL_2}*\)/#\1/g"  "${PROFILE_FILE}"
	fi
done

