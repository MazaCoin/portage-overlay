# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
#
# @ECLASS: maza.eclass
# @MAINTAINER:
# Luke Dashjr <luke_gentoo_maza@dashjr.org>
# @BLURB: common code for Bitcoin Core ebuilds
# @DESCRIPTION:
# This eclass is used in Bitcoin Core ebuilds (maza-qt, mazad,
# libmazaconsensus) to provide a single common place for the common ebuild
# stuff.
#
# The eclass provides all common dependencies as well as common use flags.

has "${EAPI:-0}" 5 || die "EAPI=${EAPI} not supported"

if [[ ! ${_MAZA_ECLASS} ]]; then

in_bcc_iuse() {
	local liuse=( ${MAZA_IUSE} )
	has "${1}" "${liuse[@]#[+-]}"
}

in_bcc_policy() {
	local liuse=( ${MAZA_POLICY_PATCHES} )
	has "${1}" "${liuse[@]#[+-]}"
}

DB_VER="4.8"
inherit autotools db-use eutils

if [ -z "$MAZA_COMMITHASH" ]; then
	inherit git-2
fi

fi

EXPORT_FUNCTIONS src_prepare src_test src_install

if in_bcc_iuse ljr || in_bcc_iuse 1stclassmsg || in_bcc_iuse zeromq || [ -n "$MAZA_POLICY_PATCHES" ]; then
	EXPORT_FUNCTIONS pkg_pretend
fi

if [[ ! ${_MAZA_ECLASS} ]]; then

# @ECLASS-VARIABLE: MAZA_COMMITHASH
# @DESCRIPTION:
# Set this variable before the inherit line, to the upstream commit hash.

# @ECLASS-VARIABLE: MAZA_IUSE
# @DESCRIPTION:
# Set this variable before the inherit line, to the USE flags supported.

# @ECLASS-VARIABLE: MAZA_LJR_DATE
# @DESCRIPTION:
# Set this variable before the inherit line, to the datestamp of the ljr
# patchset.

# @ECLASS-VARIABLE: MAZA_POLICY_PATCHES
# @DESCRIPTION:
# Set this variable before the inherit line, to a space-delimited list of
# supported policies.

MyPV="${PV/_/}"
MyPN="maza"
MyP="${MyPN}-${MyPV}"

# These are expected to change in future versions
DOCS="${DOCS} doc/README.md doc/release-notes.md"
OPENSSL_DEPEND="dev-libs/openssl:0[-bindist]"
WALLET_DEPEND="sys-libs/db:$(db_ver_to_slot "${DB_VER}")[cxx]"
[ -n "${MAZA_LJR_PV}" ] || MAZA_LJR_PV="${PV}"

case "${PV}" in
0.10*)
	MAZA_SERIES="0.10.x"
	LIBSECP256K1_DEPEND="=dev-libs/libsecp256k1-0.0.0_pre20141212"
	case "${PVR}" in
	0.10.2)
		MAZA_RBF_DIFF="16f45600c8c372a738ffef544292864256382601...a23678edc70204599299459a206709a00e039db7"
		MAZA_RBF_PATCHFILE="${MyPN}-rbf-v0.10.2.patch"
		;;
	*)
		MAZA_RBF_DIFF="16f45600c8c372a738ffef544292864256382601...4890416cde655559eba09d3fd6f79db7d0d6314a"
		MAZA_RBF_PATCHFILE="${MyPN}-rbf-v0.10.2-r1.patch"
		;;
	esac
	;;
0.11*)
	MAZA_SERIES="0.11.x"
	LIBSECP256K1_DEPEND="=dev-libs/libsecp256k1-0.0.0_pre20150423"
	# RBF is bundled with ljr patchset since 0.11.1
	if [ "${PVR}" = "0.11.0" ]; then
		MAZA_RBF_DIFF="5f032c75eefb0fe8ff79ed9595da1112c05f5c4a...660b96d24916b8ef4e0677e5d6162e24e2db447e"
		MAZA_RBF_PATCHFILE="${MyPN}-rbf-v0.11.0rc3.patch"
	fi
	;;
9999*)
	MAZA_SERIES="9999"
	LIBSECP256K1_DEPEND=">dev-libs/libsecp256k1-0.0.0_pre20150422"
	;;
*)
	die "Unrecognised version"
	;;
esac

#LJR_PV() { echo "${MAZA_LJR_PV}.${1}${MAZA_LJR_DATE}"; }
##LJR_PATCHDIR="${MyPN}-$(LJR_PV ljr).patches"
#LJR_PATCH() { echo "${WORKDIR}/${LJR_PATCHDIR}/${MyPN}-$(LJR_PV ljr).$@.patch"; }
#LJR_PATCH_DESC="http://luke.dashjr.org/programs/${MyPN}/files/${MyPN}d/luke-jr/${MAZA_SERIES}/$(LJR_PV ljr)/${MyPN}-$(LJR_PV ljr).desc.txt"

HOMEPAGE="https://github.com/mazacoin/maza"

if [ -z "$MAZA_COMMITHASH" ]; then
	EGIT_PROJECT='maza'
	EGIT_REPO_URI="git://github.com/mazacoin/maza.git https://github.com/mazacoin/maza.git"
else
	SRC_URI="https://github.com/mazacoin/${MyPN}/archive/${MAZA_COMMITHASH}.tar.gz -> ${MyPN}-v${PV}${MAZA_SRC_SUFFIX}.tgz"
	#if [ -z "${MAZA_NO_SYSLIBS}" ]; then
	#	SRC_URI="${SRC_URI} http://luke.dashjr.org/programs/${MyPN}/files/${MyPN}d/luke-jr/${MAZA_SERIES}/$(LJR_PV ljr)/${LJR_PATCHDIR}.txz -> ${LJR_PATCHDIR}.tar.xz"
	#fi
	if in_bcc_policy rbf && [ -n "${MAZA_RBF_DIFF}" ]; then
		SRC_URI="${SRC_URI} maza_policy_rbf? ( https://github.com/petertodd/maza/compare/${MAZA_RBF_DIFF}.diff -> ${MAZA_RBF_PATCHFILE} )"
	fi
	S="${WORKDIR}/${MyPN}-${MAZA_COMMITHASH}"
fi

maza_policy_iuse() {
	local mypolicy iuse_def new_MAZA_IUSE=
	for mypolicy in ${MAZA_POLICY_PATCHES}; do
		if [[ "${mypolicy:0:1}" =~ ^[+-] ]]; then
			iuse_def=${mypolicy:0:1}
			mypolicy="${mypolicy:1}"
		else
			iuse_def=
		fi
		new_MAZA_IUSE="$new_MAZA_IUSE ${iuse_def}maza_policy_${mypolicy}"
	done
	echo $new_MAZA_IUSE
}
IUSE="$IUSE $MAZA_IUSE $(maza_policy_iuse)"
if in_bcc_policy rbf && in_bcc_iuse xt; then
	REQUIRED_USE="${REQUIRED_USE} maza_policy_rbf? ( !xt )"
fi

MAZA_COMMON_DEPEND="
	${OPENSSL_DEPEND}
"
if [ "${MAZA_NEED_LIBSECP256K1}" = "1" ]; then
	MAZA_COMMON_DEPEND="${MAZA_COMMON_DEPEND} $LIBSECP256K1_DEPEND"
fi
if [ "${PN}" != "libmazaconsensus" ]; then
	MAZA_COMMON_DEPEND="${MAZA_COMMON_DEPEND} >=dev-libs/boost-1.52.0[threads(+)]"
fi
maza_common_depend_use() {
	in_bcc_iuse "$1" || return
	MAZA_COMMON_DEPEND="${MAZA_COMMON_DEPEND} $1? ( $2 )"
}
maza_common_depend_use upnp net-libs/miniupnpc
maza_common_depend_use wallet "${WALLET_DEPEND}"
maza_common_depend_use zeromq net-libs/zeromq
RDEPEND="${RDEPEND} ${MAZA_COMMON_DEPEND}"
DEPEND="${DEPEND} ${MAZA_COMMON_DEPEND}
	>=app-shells/bash-4.1
	sys-apps/sed
"
if [ "${MAZA_NEED_LEVELDB}" = "1" ]; then
	RDEPEND="${RDEPEND} virtual/maza-leveldb"
fi
if in_bcc_iuse ljr && [ "$MAZA_SERIES" = "0.10.x" ]; then
	DEPEND="${DEPEND} ljr? ( dev-vcs/git )"
fi

maza_policymsg() {
	local USEFlag="maza_policy_$1"
	in_iuse "${USEFlag}" || return
	if use "${USEFlag}"; then
		[ -n "$2" ] && einfo "$2"
	else
		[ -n "$3" ] && einfo "$3"
	fi
	maza_policymsg_flag=true
}

maza_pkg_pretend() {
	maza_policymsg_flag=false
	if use_if_iuse ljr || use_if_iuse 1stclassmsg || use_if_iuse xt || use_if_iuse zeromq; then
		einfo "Extra functionality improvements to Bitcoin Core are enabled."
		maza_policymsg_flag=true
	fi
	maza_policymsg cltv \
		"CLTV policy is enabled: Your node will recognise and assist OP_CHECKLOCKTIMEVERIFY (BIP65) transactions." \
		"CLTV policy is disabled: Your node will not recognise OP_CHECKLOCKTIMEVERIFY (BIP65) transactions."
	maza_policymsg cpfp \
		"CPFP policy is enabled: If you mine, you will give consideration to child transaction fees to pay for their parents." \
		"CPFP policy is disabled: If you mine, you will ignore transactions unless they have sufficient fee themselves, even if child transactions offer a fee to cover their cost."
	maza_policymsg dcmp \
		"Data Carrier Multi-Push policy is enabled: Your node will assist transactions with at most a single multiple-'push' data carrier output." \
		"Data Carrier Multi-Push policy is disabled: Your node will assist transactions with at most a single data carrier output with only a single 'push'."
	maza_policymsg rbf \
		"Replace By Fee policy is enabled: Your node will preferentially mine and relay transactions paying the highest fee, regardless of receive order." \
		"Replace By Fee policy is disabled: Your node will only accept the first transaction seen consuming a conflicting input, regardless of fee offered by later ones."
	maza_policymsg spamfilter \
		"Enhanced spam filter policy is enabled: Your node will identify notorious spam scripts and avoid assisting them. This may impact your ability to use some services (see link for a list)." \
		"Enhanced spam filter policy is disabled: Your node will not be checking for notorious spam scripts, and may assist them."
	$maza_policymsg_flag && einfo "For more information on any of the above, see ${LJR_PATCH_DESC}"
}

maza_prepare() {
	local mypolicy
	if [ -n "${MAZA_NO_SYSLIBS}" ]; then
		true
	elif [ "${PV}" = "9999" ]; then
		#epatch "${FILESDIR}/${PV}-syslibs.patch"
		echo "No Syslibs patch" 
	else
                echo "Not using the syslibs patch" 
		#epatch "$(LJR_PATCH syslibs)"
	fi
	if use_if_iuse ljr; then
		if [ "${MAZA_SERIES}" = "0.10.x" ]; then
			# Regular epatch won't work with binary files
			local patchfile="$(LJR_PATCH ljrF)"
			einfo "Applying ${patchfile##*/} ..."
			git apply --whitespace=nowarn "${patchfile}" || die
		else
			epatch "$(LJR_PATCH ljrF)"
		fi
	fi
	if use_if_iuse 1stclassmsg; then
		epatch "$(LJR_PATCH 1stclassmsg)"
	fi
	use_if_iuse zeromq && epatch "$(LJR_PATCH zeromq)"
	for mypolicy in ${MAZA_POLICY_PATCHES}; do
		mypolicy="${mypolicy#[-+]}"
		use maza_policy_${mypolicy} || continue
		case "${mypolicy}" in
		rbf)
			if [ -n "${MAZA_RBF_PATCHFILE}" ]; then
				epatch "${DISTDIR}/${MAZA_RBF_PATCHFILE}"
			else
				epatch "$(LJR_PATCH ${mypolicy})"
			fi
			;;
		*)
			epatch "$(LJR_PATCH ${mypolicy})"
			;;
		esac
	done
}

maza_autoreconf() {
	eautoreconf
	echo "Not building properly without leveldb/secp256k1 in src/"
	#rm -r src/leveldb || die
	#rm -r src/secp256k1 || die
}

maza_src_prepare() {
	 maza_prepare
	 maza_autoreconf
}

maza_conf() {
	local my_econf=
	if use_if_iuse upnp; then
		my_econf="${my_econf} --with-miniupnpc --enable-upnp-default"
	else
		my_econf="${my_econf} --without-miniupnpc --disable-upnp-default"
	fi
	if use_if_iuse test; then
		my_econf="${my_econf} --enable-tests"
	else
		my_econf="${my_econf} --disable-tests"
	fi
	if use_if_iuse wallet; then
		my_econf="${my_econf} --enable-wallet"
	else
		my_econf="${my_econf} --disable-wallet"
	fi
	if [ -z "${MAZA_NO_SYSLIBS}" ]; then
		my_econf="${my_econf} --disable-util-cli --disable-util-tx"
	else
		my_econf="${my_econf} --without-utils"
	fi
	if [ "${MAZA_NEED_LEVELDB}" = "1" ]; then
		# Passing --with-system-leveldb fails if leveldb is not installed, so only use it for targets that use LevelDB
		my_econf="${my_econf} --with-system-leveldb"
	fi
	econf \
		--disable-ccache \
		--disable-static \
		--with-system-libsecp256k1  \
		--without-libs    \
		--without-daemon  \
		--without-gui     \
		${my_econf}  \
		"$@"
}

maza_src_test() {
	emake check
}

maza_src_install() {
	default
	#[ "${PN}" = "libmazaconsensus" ] || rm "${D}/usr/bin/test_maza"
}

_MAZA_ECLASS=1
fi
