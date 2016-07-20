#simple test
./install-eclipse -f -c https://raw.githubusercontent.com/budhash/install-eclipse/master/profiles/git-java-mvn.cfg ./eclipse
status=$?
cat install-eclipse.log
exit $status
