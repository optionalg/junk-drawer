import xmlrpclib

sys.path.append('/usr/share/rhn')
try:
    from spacewalk.common.rhnConfig import initCFG, CFG
except:
    print "This script must run from a Satellite server."
    sys.exit(1)


# Get the creds
initCFG()
username = 'taskomatic_user'
password = CFG.SESSION_SECRET_1
api_url  = 'http://localhost/cobbler_api'

cobbler = xmlrpclib.Server(api_url)
token   = cobbler.login(username, password)


