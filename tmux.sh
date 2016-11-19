# install tmux-config
git clone https://github.com/tony/tmux-config.git ~/.tmux
cp .tmux.conf ~/.tmux.conf

# build tmux-mem-cpu-load
cd ~/.tmux
git submodule init
git submodule update
cd ~/.tmux/vendor/tmux-mem-cpu-load
cmake .
make
sudo make install
