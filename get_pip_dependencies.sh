#!/bin/bash

######################################
#
# Pour récupérer les packages depuis une VM Linux Online (avec connexion Internet) :
#
#   1. Récupérer ce script et le déposer sur une VM Linux Online (avec connexion Internet) qui possède la même version de python que celle installée sur la machine cible Offline (sans connexion Internet)
#       Sans ça, les packages et dépendences récupérés ne seront pas pas forcément les bons.
#       Exemple :
#       Si la machine cible Offline est en python 3.6.8 alors la machine source Online devra être aussi en python 3.6.8
#
#   2. Exécuter le script sur la VM Online pour récupérer le package et ses dépendences :
#       ./get_pip_dependencies.sh --download -p "<CHEMIN_ABSOLU_POUR_DEPOSER_LES PACKAGES>" -n <NOM_DU_PACKAGE_A_RECUPERER>
#       Exemple :
#       ./get_pip_dependencies.sh --download -p "/home/toto/packages/" -n pykeepass
#
#   3. Récupérer le package et ses dépendences qui ont été déposés dans le répertoire <CHEMIN_ABSOLU_POUR_DEPOSER_LES PACKAGES> sur la VM Online
#
#   4. Déposer le package et ses dépendences sur la VM Offline dans un répertoire de son choix <CHEMIN_ABSOLU_POUR_INSTALLER_LES PACKAGES>
#
#   5. Exécuter le script sur la VM Offline pour installer le package et ses dépendences à partir de ce répertoire <CHEMIN_ABSOLU_POUR_INSTALLER_LES PACKAGES> :
#       ./get_pip_dependencies.sh --install -p "<CHEMIN_ABSOLU_POUR_INSTALLER_LES PACKAGES>" --venv-alias <NOM_VIRTUAL_ENVIRONMENT> --venv-user <NOM_UTILISATEUR> -n <NOM_DU_PACKAGE_A_RECUPERER>
#       Exemple :
#       ./get_pip_dependencies.sh --install -p "/home/toto/packages/" --venv-alias ans2.10 --venv-user toto -n pykeepass
#
######################################


function usage {
  echo "USAGE:"
  echo "  $0 --download [-p|--path PATH_CACHE] [-n|--name PACKAGE] [-h|--help]"
  echo "  $0 --install [-p|--path PATH_CACHE] [-n|--name PACKAGE] [--venv-path VENV_PATH] [--venv-alias VENV_ALIAS] [--venv-user VENV_USER] [-h|--help]"
  echo "EXAMPLES:"
  echo "  Download packages and their dependances one by one on ONLINE server:"
  echo "    $0 --download -p /tmp/pip-packages -n ansible~=2.9.0"
  echo "    $0 --download -p /tmp/pip-packages -n jira"
  echo "    $0 --download -p /tmp/pip-packages -n selinux"
  echo "  Install downloaded package and their dependances one by one on OFFLINE server:"
  echo "    $0 --install -p /tmp/pip-packages -n ansible~=2.9.0 --venv-alias ans2.9 --venv-user my_user"
  echo "    $0 --install -p /tmp/pip-packages -n jira --venv-alias ans2.9 --venv-user my_user"
  echo "    $0 --install -p /tmp/pip-packages -n selinux --venv-alias ans2.9 --venv-user my_user"
  echo "  Download multiple packages and their dependances at the same time on ONLINE server:"
  echo "    $0 --download -p /tmp/pip-packages -n \"ansible~=2.9.0 jira selinux\""
  echo "  Install multiple downloaded packages and their dependances at the same time on OFFLINE server:"
  echo "    $0 --install -p /tmp/pip-packages -n \"ansible~=2.9.0 jira selinux\"  --venv-alias ans2.9 --venv-user my_user"
  echo
}

ACTION=""
PACKAGES_PATH=""
PACKAGE_NAME=""
VENV_PATH="/opt/venv"
VENV_ALIAS=""
VENV_USER="toto"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
    usage
    exit 0
    ;;
    -d|--download)
    [[ ${ACTION} -ne "" ]] && echo "Only --download, --install or --list at the same time [--download|--install]" && exit 3
    ACTION="download"
    shift # past argument
    ;;
    -i|--install)
    [[ ${ACTION} -ne "" ]] && echo "Only --download, --install or --lisd at the same time [--download|--install]" && exit 3
    ACTION="install"
    shift # past argument
    ;;
    -l|--list)
    [[ ${ACTION} -ne "" ]] && echo "Only --download, --install or --list at the same time [--download|--install]" && exit 3
    ACTION="list"
    shift # past argument
    ;;
    -p|--path)
    PACKAGES_PATH=$2
    shift # past argument
    shift # past value
    ;;
    -n|--name)
    PACKAGE_NAME=$2
    shift # past argument
    shift # past value
    ;;
    --venv-path)
    VENV_PATH=$2
    shift # past argument
    shift # past value
    ;;
    --venv-alias)
    VENV_ALIAS=$2
    shift # past argument
    shift # past value
    ;;
    --venv-user)
    VENV_USER=$2
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

[[ "${ACTION}" == "list" ]] && pip3 list && echo && exit 0

error=0
[[ "${PACKAGES_PATH}" == "" ]] && echo "Please specify a '.tar.gz' and '.whl' packages folder to use for download" && error=$((error+1))
[[ "${PACKAGE_NAME}" == "" ]] && echo "Please specify a package name to download" && error=$((error+1))
if [ "${ACTION}" == "install" ]; then
  [[ "${VENV_PATH}" == "" ]] && echo "Please specify a valid virtual environment path with '--venv-path' option" && error=$((error+1))
  [[ "${VENV_ALIAS}" == "" ]] && echo "Please specify a valid virtual environment name/alias with '--venv-alias' option" && error=$((error+1))
  [[ "${VENV_USER}" == "" ]] && echo "Please specify a valid user for virtual environment owner with '--venv-user' option" && error=$((error+1))
fi
[[ $error -ne 0 ]] && usage && exit ${error}

if [ "${ACTION}" == "install" ]; then
  rpm -qa | grep "libselinux-python3"
  [[ $? -ne 0 ]] && sudo yum install -y python3-libselinux

  id -u ${VENV_USER} >/dev/null 2>&1
  [[ $? -ne 0 ]] && echo "Sorry, user '${VENV_USER}' does not exists" && echo && exit 5
  VENV_USER_HOME=$(eval echo "~$VENV_USER")
  VENV_USER_HOME=$(eval echo "~$VENV_USER")
  VENV_USER_PROFILE=${VENV_USER_HOME}/.bash_profile
fi

case ${ACTION} in

  download)
  mkdir -p ${PACKAGES_PATH}
  pip3 download -d ${PACKAGES_PATH} ${PACKAGE_NAME}
  [[ $? -ne 0 ]] && echo "Sorry, error while downloading '${PACKAGE_NAME}' in '${PACKAGES_PATH}'" && echo && exit 20
  ;;

  install)
  if [ ! -d "${VENV_PATH}/${VENV_ALIAS}" ]; then
    echo "Creating '${VENV_PATH}' folder"
    sudo mkdir -p ${VENV_PATH}
    [[ $? -ne 0 ]] && echo "Sorry, error while creating '${VENV_PATH}' folder" && echo && exit 30
    echo "Modify owner '${VENV_USER}:' on '${VENV_PATH}' folder"
    sudo chown ${VENV_USER}: ${VENV_PATH}
    [[ $? -ne 0 ]] && echo "Sorry, error while modify owner '${VENV_USER}:' on '${VENV_PATH}' folder" && echo && exit 31
    echo "Set '750' permissions on '${VENV_PATH}' folder"
    sudo chmod 750 ${VENV_PATH}
    [[ $? -ne 0 ]] && echo "Sorry, error while set '750' permissions on '${VENV_PATH}' folder" && echo && exit 32
    echo "Creating '${VENV_PATH}/${VENV_ALIAS}' python virtual environment"
    python3 -m venv ${VENV_PATH}/${VENV_ALIAS}
    [[ $? -ne 0 ]] && echo "Sorry, error while creating '${VENV_PATH}/${VENV_ALIAS}' python virtual environment" && echo && exit 33
    echo "Adding '${VENV_ALIAS}' virtual environment alias in '${VENV_USER_PROFILE}'"
    sudo echo "alias ${VENV_ALIAS}='source ${VENV_PATH}/${VENV_ALIAS}/bin/activate'" >> ${VENV_USER_PROFILE}
    [[ $? -ne 0 ]] && echo "Sorry, error while adding '${VENV_ALIAS}' virtual environment alias in '${VENV_USER_PROFILE}'" && echo && exit 34
  fi
  echo "Loading '${VENV_ALIAS}' python virtual environment"
  . ${VENV_PATH}/${VENV_ALIAS}/bin/activate
  [[ $? -ne 0 ]] && echo "Sorry, error while loading '${VENV_ALIAS}' python virtual environment" && echo && exit 36
  echo "Upgrading 'pip'"
  #${VENV_PATH}/${VENV_ALIAS}/bin/pip3 install --upgrade --force-reinstall --no-index --find-links=file://${PACKAGES_PATH} pip
  ${VENV_PATH}/${VENV_ALIAS}/bin/pip3 install --upgrade --no-index --find-links=file://${PACKAGES_PATH} pip
  [[ $? -ne 0 ]] && echo "Sorry, error while upgrading 'pip'" && echo && exit 37
  echo "Installing '${PACKAGE_NAME}' in '${VENV_ALIAS}' python virtual environment"
  ${VENV_PATH}/${VENV_ALIAS}/bin/pip3 install --upgrade --force-reinstall --no-index --find-links=file://${PACKAGES_PATH} ${PACKAGE_NAME}
  [[ $? -ne 0 ]] && echo "Sorry, error while installing '${PACKAGE_NAME}' in '${VENV_ALIAS}' python virtual environment" && echo && exit 38
  echo ""
  deactivate
  ;;

  *)
  usage
  echo "You have to use --download or --install option"
  exit 4
  ;;

esac
