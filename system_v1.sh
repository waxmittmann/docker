MAILER_CID=$(docker run -d dockerinaction/ch2_mailer)
EXPORT MAILER_CID=$MAILER_CID
echo 1
WEB_CID=$(docker create nginx)
EXPORT WEB_CID=$WEB_CID
echo 2
AGENT_CID=$(docker create --link $WEB_CID:insideweb --link $MAILER_CID:insidemailer dockerinaction/ch2_agent)
EXPORT AGENT_CID=$AGENT_CID
echo 3
