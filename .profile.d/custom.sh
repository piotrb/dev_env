function ec2_keys() {
  echo "switching to $1 ec2 keys"
  export EC2_PRIVATE_KEY=`ls ~/.aws/$1/pk-*.pem`
  export EC2_CERT=`ls ~/.aws/$1/cert-*.pem`
}

export PYTHONPATH=/usr/local/lib/python2.6/site-packages

export PATH=$PATH:~/tmp/ec2-api-tools/bin

export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home
export EC2_HOME=/Users/piotr/tmp/ec2-api-tools/

function gemo() {
  back=`pwd`
  dir=`bundle list $1`
  cd "$dir"
  mvim .
  unset dir
  cd "$back"
  unset back
}

alias rgm="rails g migration"
alias unicorn="bundle exec unicorn"
alias rdbc="rake db:branch:cleanup"
alias be="bundle exec"
alias g="git"

#export PATH=/Users/piotr/bin/Sencha/Cmd/3.1.0.256:/usr/local/share/npm/bin:$PATH
#export SENCHA_CMD_3_0_0="/Users/piotr/bin/Sencha/Cmd/3.1.0.256"

