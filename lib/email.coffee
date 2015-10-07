# TODO: Documentation email

EmailView = require './email-view'
FolderView = require './folder-view'
{CompositeDisposable} = require 'atom'
Q = require 'q'
CSON = require 'season'
fs = require 'fs-plus'

{MailboxEditor} = require './mailbox/mailbox-editor.coffee'
MailboxEditorElement = require './mailbox/mailbox-editor-element.coffee'
MailMessageElement = require './mail/element.coffee'
{MailMessage} = require 'mailtool'

{showModalInputPanel} = require './input-view.coffee'

slugify = (s) ->
  s = s.replace /[^\w\-@]/g, '-'
  s = s.replace /^-/, ''

module.exports = Email =
  emailView: null
  modalPanel: null
  subscriptions: null

  initDirectories: ->
    @configDir  = fs.normalize "~/.mailtool"
    @configFile = fs.normalize "#{@configDir}/config.cson"
    @passwdDir  = fs.normalize "~/.mailtool/passwords"

    if not fs.existsSync @configDir
      fs.mkdirSync @configDir, 0e0700

    if not fs.existsSync @passwdDir
      fs.mkdirSync @passwdDir, 0e0700

  updateAccountSubscriptions: ->
    if @accountSubscriptions
      @accountSubscriptions.dispose()

    @accountSubscriptions = new CompositeDisposable
    mailtool = require './mail-tool'

    commands = {}
    for accountSpec in mailtool.getConfig()
      continue if accountSpec.alias

      for cfgName, cfg of mailtool.getMailerConfig accountSpec.name
        ((accountName, cfgName) =>
          accountSlug = slugify accountName
          cfgSlug     = slugify cfgName
          if cfgName is 'default'
            commands["email:send-mail-using-#{accountSlug}"] = =>
              @sendMail "#{accountName}.default"
          else
            commands["email:send-mail-using-#{accountSlug}-#{cfgSlug}"] = =>
              @sendMail "#{accountName}.#{cfgName}"
        )(accountSpec.name, cfgName)


      if mailtool.hasMailbox(accountSpec.name)
        ((accountName) =>
          commands["email:open-mailbox-for-#{accountName}"] = =>
            atom.workspace.open "mailbox://#{accountName}"
        )(accountSpec.name)

    @accountSubscriptions.add atom.commands.add 'atom-workspace', commands

  activate: (state) ->
    @initDirectories()

    @mailPreview = require './mail/preview.coffee'

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.views.addViewProvider MailboxEditor, (model) =>
      new MailboxEditorElement().initialize(model)

    @subscriptions.add atom.views.addViewProvider MailMessage, (model) =>
      new MailMessageElement().initialize(model)

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'email:send-mail': => @sendMail()
      'email:open-your-mail-configuration': => @openConfigFile()

    @updateAccountSubscriptions()

    @subscriptions.add atom.workspace.addOpener (uri) =>
      if m = uri.match /^mailbox:\/\/([^\/]*)(\/.*)?/
        [config, path] = m[1..]

        return atom.views.getView(new MailboxEditor {config, path})

      if m = uri.match /^(imap(\+tls|s)?):\/\/(?:([^:@]*)(?::[^@]*)?@)?(\w+(?:\.\w+)*)(?::(\d+))?(\/.*)?/
        [scheme, user, pass, host, port, path] = m[1..]

        return atom.views.getView(new MailboxEditor {scheme, auth: {user, pass}, host, port, path})

      if m = uri.match /^mailto:(.*)/
        texteditor = new TextEditor(uri)
        texteditor.insert "To: "+m[1]+"\n"

        texteditor.onDidSave =>
           # #TODO:0 under which circumstances save mail to (which) drafts?

           @sendMail (err, info, opts) =>
             @notifyMailSent err, info, opts
             texteditor.destroy() unless err?

        return atom.views.getView(new TextEditor(uri))

    @version = JSON.parse(fs.readFileSync "#{__dirname}/../package.json").version

    # deferred = Q.defer()
    # @mailtool.connectImap('default').then =>
    #   deferred.resolve(@mailtool.imap)
    #   @updateFolderView()
    #
    # @imap = deferred.promise

  createViews: (state) ->
#    @emailView = new EmailView(state.emailViewState)

    @folderView = new FolderView(state.folderViewState)
    @folderSelectView = new FolderSelectView(state.folderViewState)

    @folderSelectPanel = atom.workspace.addModalPanel item: @folderView.getElement(), visible: false

    @emailViewPanel

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @mailPreview.destroy()

#    @emailView.destroy()
#    @folderView.destroy()

  serialize: ->
    emailViewState: @emailView.serialize()
    folderViewState: @folderView.serialize()


  openConfigFile: ->
    atom.workspace.open(@configFile).then (editor) =>
      if editor.getText() is ""
        editor.setText '''
        YourAccountDescriptiveName:
            # for information about transport configuration see
            # https://www.npmjs.com/package/nodemailer-smtp-transport
            transport:
              host: "smtp.host.name"
              port: 465
              auth:
                user: "username"
                # pass may be the password or a path to a file containing the password
                pass: "path/to/file/containingpassord"
              secure: true

              # set this only if your mailer has a self-signed certificate
              # or you get an error about certificate.
              # rejectUnauthorized: false

            default:
              from: "Your Name <your@email.address>"
              signature: """
                 Your Signature
              """

        default: "YourAccountDescriptiveName"
        '''

  # updateFolderView: ->
  #   @imap.listWellKnownFolders().then (folderInfo) =>
  #     @folderListView.updateItems(folderInfo)
  #
  # listFolders: ->
  #   @folderView.show()
  #
  sendMail: (config=null, callback=null) ->
    if config instanceof Function
      callback = config
      config = null

    if not fs.existsSync @configFile
      return @openConfigFile()

    editor = atom.workspace.getActiveTextEditor()
    selected = editor.getSelectedText()

    if not selected
      selected = editor.getText()

    mailtool = require './mail-tool'

    # options = config: config, text: selected, xMailer: 'Atom Email #{@version}', optionDialog: ({missing, options}) =>
    #   show_input_panel(caption, initial_text, on_done, on_change, on_cancel)
    cancelMail = ->
      atom.notifications.addWarning "Sending Mail Cancelled", detail: "... by yourself"

    options =
      config: config
      text: selected
      xMailer: 'Atom Email #{@version}'
      optionDialog: (options, proceed) =>
        options = options.options

        showModalInputPanel
          label: "Subject"
          initalValue: options.subject
          onCancel: cancelMail
          onConfirm: (text) =>
            options.subject = text
            showModalInputPanel
              label: "To (Enter a comma separated list of recipient addresses)"
              initialValue: options.to
              onCancel: cancelMail
              onConfirm: (text) =>
                options.to = text
                showModalInputPanel
                  label: "Cc (Enter a comma separated list of carbon copy recipient addresses)"
                  initialValue: options.cc
                  onCancel: cancelMail
                  onConfirm: (text) =>
                    options.cc = text
                    showModalInputPanel
                      label: "Bcc (Enter a comma separated list of blind carbon copy recipient addresses)"
                      initialValue: options.bcc
                      onCancel: cancelMail
                      onConfirm: (text) =>
                        options.bcc = text
                        proceed()

    mailtool.sendMail(options)
    .then (info, errors) =>
      dummy = 1
    .progress (info) =>
      @notifyMailSent info, options
    .catch (error) =>
      @notifyMailSent err, options
    .done()

    mailtool.sendMail options, (err, info) =>
      if callback
        return callback(err, info, options)
      else
        @notifyMailSent err, info, options

  notifyMailSent: (info, options={}) =>
    if info instanceof Error
      err = info
      errors = [err]
      errors = err.errors if err.errors

      for error in errors
        atom.notifications.addError "Error sending mail :(", detail: "#{error}", stack: error.stack, dismissable: true

    else
      console.log "notify email sent", info

      if info.envelope
        detail = """
          #{info.response}
          From: #{info.envelope.from}\n
        """
        if info.accepted.length
          detail = detail + "Accepted: " + info.accepted.join(", ")
        if info.rejected.length
          detail = detail + "Rejected: " + info.rejected.join(", ")

        atom.notifications.addSuccess "Email sent :)", detail: detail

      else if info.storage
        detail = """Email stored to #{info.scheme} #{info.name} #{info.folder}"""
        atom.notifications.addSuccess "Email stored :)", detail: detail


      # atom.notifications.addError "Error sending mail :(", detail: "#{err}", stack: err.stack, dismissable: true
