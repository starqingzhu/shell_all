#! /usr/sh

#安装 bash-completion
brew install bash-completion

#下载 git 源码
git clone https://github.com/git/git.git

#下载完成后，需要将 contrib/completion/ 目录下的 git-completion.bash 文件复制到当前用户根目录下：
cp ./git/contrib/completion/git-completion.bash ~/.git-completion.bash

#在 ~/.bash_profile 文件（如果没有则需要手动创建）中添加以下代码：
#if [ -f ~/.git-completion.bash ]; then
#  . ~/.git-completion.bash
#fi

echo "if [ -f ~/.git-completion.bash ]; then" >> ~/.bash_profile
echo "	. ~/.git-completion.bash"			  >> ~/.bash_profile
echo "fi"									  >> ~/.bash_profile


#在 ~/.bashrc 文件（如果没有则需要手动创建）中添加以下内容：
#source ~/.git-completion.bash

echo "source ~/.git-completion.bash" >> ~/.bashrc