%global debug_package %{nil}

Name:           volta
Version: 0.0.0
Release:        1%{?dist}
Summary:        JavaScript toolchain manager

License:        MIT
URL:            https://github.com/volta-cli/volta
Source0: https://github.com/volta-cli/volta/releases/download/v0.0.0/volta-0.0.0-linux.tar.gz
Source1:        profile.d/volta.sh
Source2:        profile.d/volta.csh

BuildRequires:  rust-packaging
BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  make

%description
Volta is a fast JavaScript toolchain manager written in Rust.

%prep
%autosetup -n volta-%{version}
%if !%{with bundled}
%cargo_prep
%endif

%build
%if !%{with bundled}
%cargo_build
%else
# Binary repack; nothing to build
%endif

%install
rm -rf %{buildroot}
%if !%{with bundled}
%cargo_install --path crates/volta-cli
%else
mkdir -p %{buildroot}/usr/lib/volta
install -m 0755 -d %{buildroot}/usr/lib/volta
install -m 0755 -d %{buildroot}/usr/bin
# Extract prebuilt tarball
mkdir -p _tmp
cd _tmp
%{__tar} -xzf %{SOURCE0} --strip-components=1
cp -a . %{buildroot}/usr/lib/volta
cd ..
%endif

install -Dm755 %{SOURCE1} %{buildroot}/etc/profile.d/volta.sh
install -Dm755 %{SOURCE2} %{buildroot}/etc/profile.d/volta.csh
ln -s ../lib/volta/bin/volta %{buildroot}/usr/bin/volta

%check
%if !%{with bundled}
%cargo_test
%endif

%files
%license LICENSE
%doc README.md
/usr/bin/volta
/usr/lib/volta
%config(noreplace) /etc/profile.d/volta.sh
%config(noreplace) /etc/profile.d/volta.csh

%post
echo 'Volta installed. Open a new shell or source /etc/profile.d/volta.sh to use it.'
