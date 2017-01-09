Flowdock plugin for Redmine
===========================

Stream Redmine events to your Flowdock flow.

Developed on: Ruby 2.3.3, Redmine 3.3.x

Installation
------------

1. Clone this repo into `#{REDMINE_ROOT}/plugins/`.
1. Restart Redmine.
1. Connect to Flowdock and create a [new developer application](https://www.flowdock.com/oauth/applications/new) with the
 following parameters:
 Name: **Redmine**  
 Shortcut application: **Checked**  
 Optionally, upload a 128x128 pixels icon (it will be displayed on inbox messages).  
 Click **Save**
1. On the **Generate Setup URI** section, select the flow to send notification and click on generated link.
1. Fill the form and click **Create source**
1. Go back to Redmine, go to **Administration** -> **Plugins** and choose **Configure** next to the Flowdock plugin.
1. Enter the **Flowdock API token** generated on step 5 next to the projects you want to stream to Flowdock.

Generate API token 
------------------

1. Open flow integrations page: https://www.flowdock.com/settings/*your_organization*/flows/*your_flow*/integrations
1. Select Redmine and click **+ Connect Redmine** link
1. Fill the form and click **Create source**
1. Go back to Redmine, go to **Administration** -> **Plugins** and choose **Configure** next to the Flowdock plugin.
1. Enter the **Flowdock API token** generated on step 3 next to the projects you want to stream to Flowdock.
