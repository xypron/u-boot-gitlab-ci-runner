# SPDX-License-Identifier: GPL-2.0+
# This Dockerfile is used to build an image containing basic stuff to be used
# to build U-Boot and run our test suites.

FROM ubuntu:bionic-20191202
MAINTAINER Tom Rini <trini@konsulko.com>
LABEL Description=" This image is for building U-Boot inside a container"

# Make sure apt is happy
ENV DEBIAN_FRONTEND=noninteractive

# Add LLVM repository
RUN apt-get update && apt-get install -y gnupg2 wget xz-utils && rm -rf /var/lib/apt/lists/*
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
RUN echo deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main | tee /etc/apt/sources.list.d/llvm.list

# Manually install the kernel.org "Crosstool" based toolchains for gcc-7.3
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_aarch64-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_arm-linux-gnueabi.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_i386-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_m68k-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_mips-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_microblaze-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_nios2-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_powerpc-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_riscv64-linux.tar.xz | tar -C /opt -xJ
RUN wget -O - https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_sh2-linux.tar.xz | tar -C /opt -xJ

# Manually install other toolchains
RUN wget -O - https://github.com/foss-xtensa/toolchain/releases/download/2018.02/x86_64-2018.02-xtensa-dc233c-elf.tar.gz | tar -C /opt -xz
RUN wget -O - https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases/download/arc-2018.09-release/arc_gnu_2018.09_prebuilt_uclibc_le_archs_linux_install.tar.gz | tar -C /opt -xz
RUN wget -O - https://github.com/vincentzwc/prebuilt-nds32-toolchain/releases/download/20180521/nds32le-linux-glibc-v3-upstream.tar.gz | tar -C /opt -xz

# Update and install things from apt now
RUN apt-get update && apt-get install -y \
	automake \
	autopoint \
	bc \
	bison \
	build-essential \
	clang-7 \
	coreutils \
	cpio \
	cppcheck \
	curl \
	device-tree-compiler \
	dosfstools \
	e2fsprogs \
	flex \
	gdisk \
	git \
	graphviz \
	grub-efi-amd64-bin \
	grub-efi-ia32-bin \
	iasl \
	iputils-ping \
	libisl15 \
	liblz4-tool \
	libpixman-1-dev \
	libpython-dev \
	libsdl1.2-dev \
	libssl-dev \
	libudev-dev \
	libusb-1.0-0-dev \
	lzma-alone \
	lzop \
	mount \
	mtools \
	openssl \
	picocom \
	parted \
	python \
	python-dev \
	python-pip \
	python-virtualenv \
	python3-pip \
	python3-sphinx \
	rpm2cpio \
	sbsigntool \
	sloccount \
	sparse \
	srecord \
	sudo \
	swig \
	util-linux \
	virtualenv \
	zip \
	&& rm -rf /var/lib/apt/lists/*

# Manually install libmpfr4 for the toolchains
RUN wget http://mirrors.kernel.org/ubuntu/pool/main/m/mpfr4/libmpfr4_3.1.4-1_amd64.deb && dpkg -i libmpfr4_3.1.4-1_amd64.deb && rm libmpfr4_3.1.4-1_amd64.deb

# Manually install a new enough version of efitools (must be v1.5.2 or later)
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/e/efitools/efitools_1.8.1-0ubuntu2_amd64.deb && sudo dpkg -i efitools_1.8.1-0ubuntu2_amd64.deb && rm efitools_1.8.1-0ubuntu2_amd64.deb

# Build GRUB UEFI targets grubarm.efi and grubaa64.efi
RUN git clone git://git.savannah.gnu.org/grub.git /tmp/grub && \
	cd /tmp/grub && \
	git checkout grub-2.04 && \
	./bootstrap && \
	mkdir -p /opt/grub && \
	./configure --target=aarch64 --with-platform=efi \
	CC=gcc \
	TARGET_CC=/opt/gcc-7.3.0-nolibc/aarch64-linux/bin/aarch64-linux-gcc \
	TARGET_OBJCOPY=/opt/gcc-7.3.0-nolibc/aarch64-linux/bin/aarch64-linux-objcopy \
	TARGET_STRIP=/opt/gcc-7.3.0-nolibc/aarch64-linux/bin/aarch64-linux-strip \
	TARGET_NM=/opt/gcc-7.3.0-nolibc/aarch64-linux/bin/aarch64-linux-nm \
	TARGET_RANLIB=/opt/gcc-7.3.0-nolibc/aarch64-linux/bin/aarch64-linux-ranlib && \
	make && \
	./grub-mkimage -O arm64-efi -o /opt/grub/grubaa64.efi --prefix= -d \
	grub-core cat chain configfile echo efinet ext2 fat halt help linux \
	lsefisystab loadenv lvm minicmd normal part_msdos part_gpt reboot \
	search search_fs_file search_fs_uuid search_label serial sleep test \
	true && \
	make clean && \
	./configure --target=arm --with-platform=efi \
	CC=gcc \
	TARGET_CC=/opt/gcc-7.3.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-gcc \
	TARGET_OBJCOPY=/opt/gcc-7.3.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-objcopy \
	TARGET_STRIP=/opt/gcc-7.3.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-strip \
	TARGET_NM=/opt/gcc-7.3.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-nm \
	TARGET_RANLIB=/opt/gcc-7.3.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-ranlib && \
	make && \
	./grub-mkimage -O arm-efi -o /opt/grub/grubarm.efi --prefix= -d \
	grub-core cat chain configfile echo efinet ext2 fat halt help linux \
	lsefisystab loadenv lvm minicmd normal part_msdos part_gpt reboot \
	search search_fs_file search_fs_uuid search_label serial sleep test \
	true && \
	make clean && \
	./configure --target=riscv64 --with-platform=efi \
	CC=gcc \
	TARGET_CC=/opt/gcc-7.3.0-nolibc/riscv64-linux/bin/riscv64-linux-gcc \
	TARGET_OBJCOPY=/opt/gcc-7.3.0-nolibc/riscv64-linux/bin/riscv64-linux-objcopy \
	TARGET_STRIP=/opt/gcc-7.3.0-nolibc/riscv64-linux/bin/riscv64-linux-strip \
	TARGET_NM=/opt/gcc-7.3.0-nolibc/riscv64-linux/bin/riscv64-linux-nm \
	TARGET_RANLIB=/opt/gcc-7.3.0-nolibc/riscv64-linux/bin/riscv64-linux-ranlib && \
	make && \
	./grub-mkimage -O riscv64-efi -o /opt/grub/grubriscv64.efi --prefix= -d \
	grub-core cat chain configfile echo efinet ext2 fat halt help linux \
	lsefisystab loadenv lvm minicmd normal part_msdos part_gpt reboot \
	search search_fs_file search_fs_uuid search_label serial sleep test \
	true && \
	rm -rf /tmp/grub

RUN git clone git://git.qemu.org/qemu.git /tmp/qemu && \
	cd /tmp/qemu && \
	git submodule update --init dtc && \
	git checkout v4.2.0 && \
	./configure --prefix=/opt/qemu --target-list="aarch64-softmmu,arm-softmmu,i386-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,ppc-softmmu,riscv64-softmmu,x86_64-softmmu,xtensa-softmmu" && \
	make -j$(nproc) all install && \
	rm -rf /tmp/qemu

# Create our user/group
RUN echo uboot ALL=NOPASSWD: ALL > /etc/sudoers.d/uboot
RUN useradd -m -U uboot
USER uboot:uboot

# Create the buildman config file
RUN /bin/echo -e "[toolchain]\nroot = /usr" > ~/.buildman
RUN /bin/echo -e "kernelorg = /opt/gcc-7.3.0-nolibc/*" >> ~/.buildman
RUN /bin/echo -e "arc = /opt/arc_gnu_2018.09_prebuilt_uclibc_le_archs_linux_install" >> ~/.buildman
RUN /bin/echo -e "\n[toolchain-prefix]\nxtensa = /opt/2018.02/xtensa-dc233c-elf/bin/xtensa-dc233c-elf-" >> ~/.buildman;
RUN /bin/echo -e "\nnds32 = /opt/nds32le-linux-glibc-v3-upstream/bin/nds32le-linux-" >> ~/.buildman;
RUN /bin/echo -e "\n[toolchain-alias]\nsh = sh2" >> ~/.buildman
RUN /bin/echo -e "\nriscv = riscv64" >> ~/.buildman
RUN /bin/echo -e "\nsandbox = x86_64" >> ~/.buildman
RUN /bin/echo -e "\nx86 = i386" >> ~/.buildman;
