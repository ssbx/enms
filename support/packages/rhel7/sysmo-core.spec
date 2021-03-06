#
# rpmbuild -ba sysmo-core.spec
#

Name:		sysmo-core
Version:	@SYSMO_CORE_VERSION@
Release:	@SYSMO_CORE_BUILD@%{?dist}
Summary:	Sysmo Core server
Group:		Application/Productivity
License:	GPLv3+
URL:		https://sysmo-nms.github.io
Source:	        sysmo-core-@SYSMO_CORE_VERSION@.tar.gz

Requires: java

%define debug_package %{nil}

%global sysmo_app_name sysmo-nms
%global sysmo_user_name sysmo-nms
%global sysmo_group_name sysmo-nms

%global state_server_port 9760
%global web_server_port 9759
%global sysmo_server_port 9758


%description
Sysmo-Core is the main sysmo service.


%prep
%setup -q


%build
git submodule update --init
rake release


%install
# if build localy: cd sysmo
RELEASE_DIR="_build/default/rel/sysmo"

SYSMO_LIB=%{buildroot}/usr/lib64/%{sysmo_app_name}
mkdir -p ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/bin ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/erts-* ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/java_apps ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/lib ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/releases ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/ruby ${SYSMO_LIB}
cp -R ${RELEASE_DIR}/utils ${SYSMO_LIB}

SYSMO_ETC=%{buildroot}/etc/%{sysmo_app_name}
mkdir -p ${SYSMO_ETC}
cp -R ${RELEASE_DIR}/etc/*  ${SYSMO_ETC}/
ln -s ../../../etc/%{sysmo_app_name} ${SYSMO_LIB}/etc

SYSMO_LOG=%{buildroot}/var/log/%{sysmo_app_name}
mkdir -p ${SYSMO_LOG}/sasl
ln -s ../../../var/log/%{sysmo_app_name} ${SYSMO_LIB}/log

SYSMO_VAR=%{buildroot}/var/lib/%{sysmo_app_name}
mkdir -p ${SYSMO_VAR}/data/monitor
mkdir -p ${SYSMO_VAR}/data/states
mkdir -p ${SYSMO_VAR}/data/events
cp -R ${RELEASE_DIR}/docroot ${SYSMO_VAR}/
ln -s ../../../var/lib/%{sysmo_app_name}/data ${SYSMO_LIB}/data
ln -s ../../../var/lib/%{sysmo_app_name}/docroot ${SYSMO_LIB}/docroot

mkdir -p %{buildroot}/usr/lib/systemd/system
cp support/packages/rhel7/sysmo.service %{buildroot}/usr/lib/systemd/system/

%pre
if [ $1 -gt 1 ]; then
  # It is an upgrade. Sysmo service is allready installed
  /usr/bin/systemctl stop sysmo
  EPMD_EXE=$(find /usr/lib64/%{sysmo_app_name}/*/bin -name epmd)
  if [ $EPMD_EXE != "" ]; then
    $EPMD_EXE -kill > /dev/null 2>&1 || true
  fi
fi


# INSTALL

%post
/bin/getent group %{sysmo_group_name} > /dev/null \
	|| /sbin/groupadd -r %{sysmo_group_name}
/bin/getent passwd %{sysmo_user_name} > /dev/null \
	|| /sbin/useradd -r -M -d /usr/lib64/%{sysmo_app_name} \
		-s /sbin/nologin \
		-g %{sysmo_group_name} %{sysmo_user_name}

chown -R %{sysmo_user_name}:%{sysmo_group_name} /usr/lib64/%{sysmo_app_name}
chown -R %{sysmo_user_name}:%{sysmo_group_name} /etc/%{sysmo_app_name}
chown -R %{sysmo_user_name}:%{sysmo_group_name} /var/lib/%{sysmo_app_name}
chown -R %{sysmo_user_name}:%{sysmo_group_name} /var/log/%{sysmo_app_name}

find /usr/lib64/%{sysmo_app_name} -type d -exec chmod 775 {} \;
find /usr/lib64/%{sysmo_app_name} -type f -perm /u+x -exec chmod 554 {} \;
find /usr/lib64/%{sysmo_app_name} -type f ! -perm /u+x -exec chmod 664 {} \;

find /etc/%{sysmo_app_name} -type d -exec chmod 775 {} \;
find /etc/%{sysmo_app_name} -type f -exec chmod 664 {} \;
chmod 600 /etc/%{sysmo_app_name}/users.xml
chmod 600 /etc/%{sysmo_app_name}/vm.args

find /var/lib/%{sysmo_app_name} -type d -exec chmod 775 {} \;
find /var/lib/%{sysmo_app_name} -type f -exec chmod 660 {} \;

find /var/log/%{sysmo_app_name} -type d -exec chmod 775 {} \;
find /var/log/%{sysmo_app_name} -type f -exec chmod 664 {} \;

chown root:%{sysmo_group_name} /usr/lib64/%{sysmo_app_name}/utils/pping
chmod 4554 /usr/lib64/%{sysmo_app_name}/utils/pping

if [ -e /usr/lib64/%{sysmo_app_name}/.erlang.cookie ]; then
  chmod 400 /usr/lib64/%{sysmo_app_name}/.erlang.cookie
fi

if [ $1 -gt 1 ]; then
  # It is an upgrade start sysmo if allready started
  /usr/bin/systemctl is-enabled sysmo > /dev/null 2>&1 
  if [ $? -eq 0 ]; then
    /usr/bin/systemctl disable sysmo > /dev/null 2>&1 || true
    /usr/bin/systemctl enable sysmo > /dev/null 2>&1 || true
    /usr/bin/systemctl start sysmo > /dev/null 2>&1 || true
  fi
fi


%preun
if [ $1 -eq 0 ]; then
  # It is an uninstall
  /usr/bin/systemctl stop sysmo
  /usr/bin/systemctl disable sysmo
  EPMD_EXE=$(find /usr/lib64/%{sysmo_app_name}/*/bin -name epmd)
  if [ $EPMD_EXE != "" ]; then
    $EPMD_EXE -kill > /dev/null 2>&1 || true
  fi
fi

# UNINSTALL

%postun


%files
%dir /usr/lib64/%{sysmo_app_name}
%dir /etc/%{sysmo_app_name}
%dir /etc/%{sysmo_app_name}/nchecks
%dir /etc/%{sysmo_app_name}/ssl
%dir /var/log/%{sysmo_app_name}
%dir /var/log/%{sysmo_app_name}/sasl
%dir /var/lib/%{sysmo_app_name}
%dir /var/lib/%{sysmo_app_name}/docroot
%dir /var/lib/%{sysmo_app_name}/data/events
%dir /var/lib/%{sysmo_app_name}/data/monitor
%dir /var/lib/%{sysmo_app_name}/data/states

/usr/lib/systemd/system/sysmo.service
/usr/lib64/%{sysmo_app_name}/*
%config(noreplace) /etc/%{sysmo_app_name}/app.config
%config(noreplace) /etc/%{sysmo_app_name}/sysmo.properties
%config(noreplace) /etc/%{sysmo_app_name}/users.xml
%config(noreplace) /etc/%{sysmo_app_name}/vm.args
/etc/%{sysmo_app_name}/ssl/gen_certificates
/etc/%{sysmo_app_name}/nchecks/*
/var/lib/%{sysmo_app_name}/docroot/*


%changelog
* Tue Nov 10 2015 Sebastien Serre <ssbx@sysmo.io> 1.1.0-1
- Initial rpm build
