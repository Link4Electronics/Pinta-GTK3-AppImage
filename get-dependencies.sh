#!/bin/sh

set -eu

ARCH="$(uname -m)"

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm dotnet-sdk

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Building pinta (gtk3 branch)..."
echo "---------------------------------------------------------------"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

git clone --depth 1 --branch gtk3 https://github.com/PintaProject/Pinta.git ./pinta-src && (
	cd ./pinta-src
	# The gtk3 branch targets net7.0; bump to net10.0 to match the dotnet-sdk
	sed -i 's/net7.0/net10.0/g' Directory.Build.props

	dotnet publish ./Pinta/Pinta.csproj \
		-c Release                  \
		-r linux-x64                \
		--self-contained true       \
		-p:BuildTranslations=true   \
		-p:PublishDir=/usr/lib/pinta

	# dlopen'd lazily only when tracing, would drag in liblttng-ust
	rm -f /usr/lib/pinta/libcoreclrtraceptprovider.so

	cp -r /usr/lib/pinta/icons/hicolor /usr/share/icons
	sed 's/^_//' ./xdg/pinta.desktop.in > /usr/share/applications/pinta.desktop
	cp -r /usr/lib/pinta/locale/. /usr/share/locale

	awk -F'<|>' '/<Version>/{print $3; exit}' ./Directory.Build.props | sed 's/\.0$//' > ~/version
)
