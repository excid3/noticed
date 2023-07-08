# WebPush delivery Method

Sends a browser based notification via WebPush.

`deliver_by :web_push, data_method: :web_push_data`

## Options

- `data_method` - _Optional_

  The method called on the notification for the data hash. Defaults to `:web_push_data`

## Setup

`rails generate noticed:web_push` will copy over sample javascript files and import them into `application.js`. A sample `service_worker.js` will be copied into the `public/` folder. This generator will also generate VAPID credentials which you will want to copy (`rails credentials:edit`).

### Service Worker Note

Service workers can only be used in the path they are located at and subpaths ie serving `assets/service_worker.js` will only work within the `assets` folder. Not ideal!

There are header you can set to avoid this, but to keep things simple, I've just included it into the public folder. It is likely you want to handle this differently, but this is a simple starting place.

## Handling Failures

When a subscription fails (expired or unauthorized), it is deleted.
