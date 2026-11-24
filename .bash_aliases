# Some sudo aliases
alias apt='sudo apt'
alias apt-get='sudo apt-get'
alias dpkg='sudo dpkg'
alias dpkg-reconfigure='sudo dpkg-reconfigure'
alias gdebi='sudo gdebi'
alias mt='sudo mt'
alias rc-update='sudo /sbin/rc-update'
alias snap='sudo snap'
alias updatedb='sudo /usr/bin/updatedb'
alias update-alternatives='sudo update-alternatives'
alias pm-hibernate='sudo /usr/sbin/pm-hibernate'
alias iotop='sudo iotop'

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Other stuff
alias mkdir='mkdir -p'

alias toolsdist='make dist; ( cd /usr/local; sudo tar xvzof ~/tools/dist.tar.gz )'

# SSH to twin2 virtual machines
alias sshtwin20='ssh -A -p 50020 -o StrictHostKeyChecking=no twin2.scilifelab.se'
alias sshtwin21='ssh -A -p 50021 -o StrictHostKeyChecking=no twin2.scilifelab.se'
alias sshtwin23='ssh -A -p 50023 -o StrictHostKeyChecking=no twin2.scilifelab.se'

# The first is for Rstudio server itself (http://localhost:8700), the second for a rendering window (http://localhost:4200).
# The second assumes one has started `quarto preview file.qmd --no-browser --port 4200` in Rstudio.
alias seqrsts='ssh -N -L 8700:localhost:8787 -L 4200:localhost:4200 sequoia'
alias pacrsts='ssh -N -L 8701:localhost:8787 pacific'
alias southrsts='ssh -N -L 8702:localhost:8787 southern'

alias seqanvio='ssh -N -L 8080:localhost:8080 sequoia'
alias pacanvio='ssh -N -L 8081:localhost:8080 pacific'

alias seqms='ssh  -N -L 8001:10.20.20.1:443 sequoia'

# Turn on and off compositing that affects Zoom
alias compoff='xfconf-query -c xfwm4 -p /general/use_compositing -s false'
alias compon='xfconf-query -c xfwm4 -p /general/use_compositing -s true'
alias compcheck='xfconf-query -c xfwm4 -p /general/use_compositing'
