
# model
class MailboxEditor
  constructor: (options={}) ->
    @mailtool = new MailTool "~/.mailtool.cson"
    @imap = @mailtool.connectImap options

  
