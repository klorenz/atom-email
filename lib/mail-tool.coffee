{MailTool} = require 'mailtool'
fs = require 'fs-plus'

configFile = "~/.mailtool/config.cson"

mailtool = new MailTool configFile

module.exports = mailtool
