wget -q https://github.com/holesail/holesail/releases/latest/download/linux-arm64.zip -O holesail.zip && \
unzip -o holesail.zip && \
chmod +x holesail && \
sudo mv holesail /usr/local/bin/ && \
rm holesail.zip && \
echo "Holesail installed successfully to /usr/local/bin/holesail"