#!/bin/bash

LDIF="$1"
if [[ -f "$LDIF" ]] ; then
	/etc/init.d/slapd stop
	rm -rf /var/lib/openldap-data/*
	slapadd -l "$LDIF"
	chown ldap:ldap /var/lib/openldap-data/*
	/etc/init.d/slapd start
fi
