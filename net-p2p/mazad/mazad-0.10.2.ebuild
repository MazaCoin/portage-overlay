# Copyright 2010-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

MAZA_COMMITHASH="55f277b83774276f8e06238d06d72757d769214e"
MAZA_LJR_PV="0.10.2"
MAZA_LJR_DATE="20160204"
MAZA_IUSE="examples logrotate test upnp +wallet"
MAZA_POLICY_PATCHES=""
MAZA_NEED_LEVELDB=1
MAZA_NEED_LIBSECP256K1=1
inherit bash-completion-r1 maza user systemd

DESCRIPTION="Original MAZA crypto-currency wallet for automated services" 
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm ~arm64 x86 ~amd64-linux ~x86-linux"

RDEPEND="
	logrotate? (
		app-admin/logrotate
	)
"
DEPEND="${RDEPEND}"

pkg_setup() {
	local UG='maza'
	enewgroup "${UG}"
	enewuser "${UG}" -1 -1 /var/lib/maza "${UG}"
}

src_prepare() {
	epatch "${FILESDIR}/miniupnpc-14.patch"
	epatch "${FILESDIR}/0.10.0-openrc-compat.patch"
	maza_src_prepare
}

src_configure() {
	# NOTE: --enable-zmq actually disables it
	maza_conf \
		--with-daemon
}

src_install() {
	maza_src_install

	insinto /etc/maza
	newins "${FILESDIR}/maza.conf" maza.conf
	fowners maza:maza /etc/maza/maza.conf
	fperms 600 /etc/maza/maza.conf

	newconfd "contrib/init/mazad.openrcconf" ${PN}
	newinitd "contrib/init/mazad.openrc" ${PN}
	systemd_dounit "${FILESDIR}/mazad.service"

	keepdir /var/lib/maza/.maza
	fperms 700 /var/lib/maza/
	fowners maza:maza /var/lib/maza/
	fowners maza:maza /var/lib/maza/maza.
	dosym /etc/maza/maza.conf /var/lib/maza/.maza/maza.conf

	dodoc doc/assets-attribution.md doc/tor.md
	doman contrib/debian/manpages/{mazad.1,maza.conf.5}

	newbashcomp contrib/${PN}.bash-completion ${PN}

	if use examples; then
		docinto examples
		dodoc -r contrib/{bitrpc,qos,spendfrom,tidy_datadir.sh}
	fi

	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}/mazad.logrotate-r1" mazad
	fi
}
