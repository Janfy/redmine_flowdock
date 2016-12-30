class FlowdockListener < Redmine::Hook::Listener
  INTEGRATION_SOURCE = 'Redmine'
  FLOWDOCK_API_HOST = 'api.flowdock.com'

  @@renderer = FlowdockRenderer.new

  def controller_issues_new_after_save(context = {})
    set_data(context[:issue])
    issue = context[:issue]

    title = "a ajouté une demande : #{@tracker} \##{issue.id}"
    body = ''

    send_message!(title, body)
  end

  def controller_issues_edit_after_save(context = {})
    set_data(context[:issue])

    if @has_private_notes
      subject = 'a ajouté une note privée'
      body = @@renderer.details_to_html(context[:journal])
    elsif @has_notes
      subject = 'a ajouté une note'
      body = @@renderer.details_to_html(context[:journal]) + @@renderer.notes_to_html(context[:journal])
    else
      subject = 'a mis à jour la demande'
      body = @@renderer.details_to_html(context[:journal])
    end

    send_message!(subject, body)
  end

  def controller_issues_bulk_edit_before_save(context = {})
    controller_issues_edit_after_save(context)
  end

  def controller_issues_before_delete(context = {})

    context[:issues].each { |issue|
      set_data(issue)
      @issue_deleted = true

      send_message!('a supprimé une demande', '')
    }
  end

  protected

  def fields
    fields = []

    if @issue_deleted == false
      fields.push({
                      label: l(:field_status),
                      value: @issue.status.name
                  })
    else
      fields.push({
                      label: l(:field_status),
                      value: l(:label_deleted).capitalize
                  })
    end

    fields.push({
                    label: l(:field_project),
                    value: "<a href=\"#{@project_url}\">#{@project.name}</a>"
                })
    fields.push({
                    label: l(:field_tracker),
                    value: "<a href=\"#{@tracker_url}\">#{@tracker}</a>"
                })
    fields.push({
                    label: l(:field_priority),
                    value: @issue.priority.name
                })
    if @issue.assigned_to
      fields.push({
                      label: l(:field_assigned_to),
                      value: "<a href=\"#{@assigned_to_url}\">#{@issue.assigned_to.name}</a>"
                  })
    end
    fields.push({
                    label: l(:field_start_date),
                    value: @issue.start_date
                })
    fields.push({
                    label: l(:field_due_date),
                    value: @issue.due_date
                })
    fields.push({
                    label: l(:field_done_ratio),
                    value: @issue.done_ratio
                })
    fields
  end

  def author
    {
        name: @user_name,
        email: @user_email
    }
  end

  # red, green, yellow, cyan, orange, grey, black, lime, purple, blue
  def status
    if @issue_deleted == false
      case @issue.status.id
        when 1 then # Nouveau
          color='lime'
        when 2 then # En cours
          color = 'cyan'
        when 3 then # Résolu
          color = 'green'
        when 4 then # Commentaire/En attente
          color = 'purple'
        when 5 then # Fermé
          color = 'grey'
        when 6 then # Rejeté
          color = 'red'
        else
          color = 'blue'
      end
      {
          value: @issue.status.name,
          color: color
      }
    else
      {
          value: l(:label_deleted).capitalize,
          color: 'red'
      }
    end
  end

  def issue_id
    "#{@project.identifier}:#{@issue.project.id}:#{@issue.id}"
  end

  def build_json(title, body)
    {
        event: 'activity',
        title: title,
        body: body,
        author: author,
        external_thread_id: issue_id,
        thread: {
            title: "#{@issue.subject}",
            external_url: @issue_deleted == true ? '' : @url,
            body: @@renderer.description_to_html(@issue.description),
            status: status,
            fields: fields
        }
    }
  end

  def avatar_url(email)
    id = Digest::MD5.hexdigest(email.to_s.downcase)
    "https://secure.gravatar.com/avatar/#{id}?s=120&r=pg"
  end

  # Can be called after set_data
  def api_token
    raise "set_data not called before api_token" unless @project
    token = Setting.plugin_redmine_flowdock[:api_token][@project.identifier]
    token = nil if token == ''
    token
  end

  def set_data(object)
    @user_name = User.current.name
    @user_email = User.current.mail
    @url = get_url(object)
    @issue_deleted = false

    case object
      when Issue then
        @issue = object
        @project = @issue.project
        @project_url = get_url(@issue.project)
        @tracker = @issue.tracker.name
        @tracker_url = get_url(@issue.tracker)
        @has_notes = @issue.current_journal && @issue.current_journal.notes
        @has_private_notes = @issue.current_journal && @issue.current_journal.private_notes
        if @issue.assigned_to
          @assigned_to_url = get_url(@issue.assigned_to)
        end
        @issue.custom_field_values.each { |cf|
          if cf.custom_field.name.downcase == 'tags'
            @tags = cf.value
            break
          end
        }
      else
        raise "FlowdockListener#set_data called for unknown object #{object.inspect}"
    end

    @project_name = @project.name
  end

  def send_message!(title, body)
    token = api_token
    return unless token

    # :project => @project_name.gsub(/[^\w\s]/,' '),

    json = build_json(title, body).merge(flow_token: token).merge(tags: @tags.split(',').map(&:strip))

    # Don't block while posting to Flowdock.
    Thread.new do
      send_http_request!(json)
    end
  end

  def send_http_request!(json)
    req = Net::HTTP::Post.new('/messages/')
    req['Content-Type'] = 'application/json'
    req.body = json.to_json

    if ENV['http_proxy']
      proxy_string = ENV['http_proxy']
      proxy_uri = URI.parse(proxy_string)
      Rails.logger.info("Using proxy from ENV['http_proxy']: #{proxy_uri}")
      http = Net::HTTP.new(FLOWDOCK_API_HOST, 443, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
    else
      http = Net::HTTP.new(FLOWDOCK_API_HOST, 443)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    begin
      http.start do |conn|
        conn.request(req)
      end
    rescue => ex
      Rails.logger.error "Error posting to Flowdock: #{ex.to_s}"
    end
  end

  def get_url(object)
    path = case object
             when Issue then
               "issues/#{object.id}"
             when WikiPage then
               "projects/#{object.wiki.project.identifier}/wiki/#{object.title}"
             when Project then
               "projects/#{object.identifier}"
             when User then
               "users/#{object.id}"
             when Tracker then
               return "#{@project_url}/issues?set_filter=1&tracker_id=#{object.id}"
             else
               raise "FlowdockListener#get_url called for an unknown object #{object.inspect}"
           end

    "#{Setting[:protocol]}://#{Setting[:host_name]}/#{path}"
  end

end
