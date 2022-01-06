module Noticed
  module DeliveryMethods
    class Fcm < Base
      attr_reader :credentials_path, :project_id

      BASE_URI = "https://fcm.googleapis.com/v1/projects/"

      def initialize(credentials_path:, project_id:)
        @credentials_path = credentials_path
        @project_id = project_id
      end

      def notify(payload)
        # project_id = json_key["project_id"]
        post("#{BASE_URI}#{project_id}/messages:send", headers: { authorization: "Bearer #{access_token}" }, json: { message: payload })
      end

      def access_token
        # token = authorizer.fetch_access_token!
        # token["access_token"]
        "di1YsOtPRRaWXg9Qll6C-O:APA91bGNSOR-Of5CYUmarzQYvXAuqvvPbK492FX1Bv1jwSi-ubTtUkwe8yPZU1mCAdStRlwwge120QpqbjbdOfnAsqxVowFXEozuDX3TJX3wHU8V2nqwAfJk4qLOQQXYq0xABm4XvlgX"
      end

      def authorizer
        @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: json_key,
          scope: "https://www.googleapis.com/auth/firebase.messaging",
        )
      end

      def json_key
        @json_key ||= if credentials_path.respond_to?(:read)
                        credentials_path
                      else
                        File.open(credentials_path)
                      end
      end
    end
  end
end

# payload = {
#   token: "efz2xH7ElXktnbWRbML3lC:APA91bG-qdGh1nmmJPyNE7xvmUL_9WKi2mmq9PY0uDh8ugFGvHx4xz7kH7HJjXUTtj59k-hc99TCwwL_cefaJPyz_Pa1H9w0kUrse6-NykSWCS-RD2HC5qYPVQY5rNRam1nPmpMpeRnr",
#   data: {
#     payload: {
#       data: {
#         id: 1
#       }
#     }.to_json
#   },
#   notification: {
#     title: "Hey Chris",
#     body: "Am I worky?",
#   },
#   android: {},
#   apns: {
#     payload: {
#       aps: {
#         sound: "default",
#         category: "#{Time.zone.now.to_i}"
#       }
#     }
#   },
#   fcm_options: {
#     analytics_label: 'Label'
#   }
# }
