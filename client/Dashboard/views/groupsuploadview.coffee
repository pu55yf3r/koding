class GroupsUploadView extends JView

  constructor: (options = {}, data) ->

    options.uploaderOptions or= {}

    super options, data

    {cssClass, size, title} = @getOptions().uploaderOptions

    @uploadArea   = new DNDUploader
      uploadToVM  : no
      cssClass    : cssClass or "groups-uploader"
      title       : title    or "Drop your image here!"
      size        : size

    @cancelButton = new KDButtonView
      title       : "Cancel"
      cssClass    : "solid red upload-button cancel"
      callback    : =>
        @emit "UploadCancelled"
        @destroy()

    @saveButton   = new KDButtonView
      title       : "Save"
      cssClass    : "solid green upload-button save"
      disabled    : yes
      callback    : => @uploadToS3()

    @loader       = new KDLoaderView
      cssClass    : "group-upload-loader"
      showLoader  : no
      size        :
        width     : 24

    @uploadArea.on "dropFile", ({origin, content}) =>
      if origin is "external"
        @btoaContent = btoa content
        @uploadArea.updatePartial ""
        @saveButton.enable()
        @btoaContent = btoa content
        @preview "data:image/png;base64,#{@btoaContent}"

  preview: (imageData) ->
    @previewView?.destroy()
    @previewView = new KDCustomHTMLView
      tagName    : "img"
      cssClass   : "group-image-preview"
      attributes :
        src      : imageData

    @uploadArea.addSubView @previewView

  uploadToS3: ->
    #TODO : change the address and name of the logo
    group     = KD.singletons.groupsController.getCurrentGroup()
    imageName = "#{group.slug}-logo-#{Date.now()}.png"

    FSHelper.s3.upload imageName, @btoaContent, "groups", group.slug, (err, url) =>
      @loader.hide()
      if err 
        message = if err.code is 100 then "First you have to create a VM"
        else "Error while uploading photo." 
        return KD.showError message
      @emit "FileUploadDone", url
      @destroy()

  pistachio: ->
    """
      {{> @uploadArea}}
      {{> @cancelButton}}
      {{> @saveButton}}
      {{> @loader}}
    """
