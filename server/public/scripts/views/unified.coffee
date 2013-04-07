define [
  'backbone-full'
  'cs!views/view'
  'cs!views/statusbar'
  'cs!client/client'
  'jade!templates/unified'
], (
  Backbone
  View
  StatusBarView
  TriggerClient
  template
) ->
  $ = Backbone.$

  class UnifiedView extends View
    el: '#unified-container'
    template: template

    constructor: (@app) -> super()

    afterRender: ->
      statusBarView = new StatusBarView @app
      statusBarView.render()

      $window = $(window)
      $document = $(document)
      $view3d = $('#view3d')

      client = @client = new TriggerClient $view3d[0], @app.root
      client.camera.eulerOrder = 'ZYX'

      $document.on 'keyup', (event) -> client.onKeyUp event
      $document.on 'keydown', (event) -> client.onKeyDown event

      do layout = ->
        statusbarHeight = statusBarView.height()
        $view3d.height $window.height() - statusbarHeight
        $view3d.css 'top', statusbarHeight
        client.setSize $view3d.width(), $view3d.height()
      $window.on 'resize', layout

      $document.on 'click', 'a.login', (event) ->
        width = 1000
        height = 700
        left = (window.screen.width - width) / 2
        top = (window.screen.height - height) / 2
        popup = window.open "/login?popup=1",
                            "Login",
                            "width=#{width},height=#{height},left=#{left},top=#{top}"
        if popup
          timer = setInterval ->
            if popup.closed
              clearInterval timer
              Backbone.trigger 'app:checklogin'
          , 1000
        # If the popup fails to open, allow the link to trigger as normal.
        not popup

      $document.on 'click', 'a.logout', (event) ->
        $.ajax('/v1/auth/logout')
        .done (data) ->
          Backbone.trigger 'app:logout'
        false

      @currentView = null

      requestAnimationFrame @update

    lastTime = null
    update: (time) =>
      lastTime or= time
      deltaTime = Math.max 0, Math.min 0.1, (time - lastTime) * 0.001

      @currentView?.update deltaTime, time

      @client.update deltaTime
      @client.render()

      requestAnimationFrame @update

    getView: -> @currentView

    setView: (view) ->
      container = $('#unified-child')
      if @currentView
        @currentView.destroy()
        container.empty()
      @currentView = view
      if view
        container.append view.el
      return