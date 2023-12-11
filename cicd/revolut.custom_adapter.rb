{
  title: "Revolut",

  # API key authentication example. See more examples at https://docs.workato.com/developing-connectors/sdk/guides/authentication.html
  connection: {
    fields: [
      {
        name: 'api_domain',
        control_type: 'subdomain',
        label: 'API subdomain',
        hint: 'API domain.',
        optional: 'false',
      },
      {
        name: 'authorization_domain',
        control_type: 'subdomain',
        label: 'Authorization subdomain',
        hint: 'Authorization domain to login with your credentials.',
        optional: 'false',
      },
      {
        name: 'client_id',
        control_type: :text,
        label: 'Client ID',
        hint: 'Identifier of the Oauth client.',
        optional: false,
      },
      {
        name: 'client_secret',
        label: 'Client secret',
        hint: 'Secret of the Oauth client.',
        optional: true
      },
      {
        name: 'iss',
        label: 'Issuer',
        optional: false,
        hint: 'The email address of the service account'
      },
      {
        name: 'sub',
        label: 'Email address',
        optional: false,
        hint: 'Email address of the user that you are impersonating'
      },
      {
        name: 'private_key',
        optional: false,
        hint: 'Copy and paste the private key that came from the downloaded json.<br>' \
          "Click <a href='https://developers.google.com/identity/protocols/oauth2/service-account/' " \
          "target='_blank'>here</a> to learn more about Google Service Accounts.",
        control_type: 'password',
        multiline: true
      }
    ],
    base_uri: lambda { |connection| "#{connection['api_domain']}" },
    authorization: {
      type: 'oauth2',
      authorization_url:
      lambda do |connection|
        "#{connection['authorization_domain']}/app-confirm?client_id=#{connection['client_id']}&response_type=code&redirect_uri=https://www.workato.com/oauth/callback"
      end,
      #       token_url: lambda { |connection| "#{connection['authorization_domain']}/oauth2/token" },
      #       client_id: lambda { |connection| "#{connection['client_id']}" },
      #       client_secret: lambda { |connection| "#{connection['client_secret']}" },
      acquire: lambda do |connection, auth_code|
        #         encoded_string = "#{connection['client_id']}:#{connection['client_secret']}".encode_base64
        jwt_body_claim = {
          #           "iat": now.to_i,
          "exp": 1.day.from_now.to_i,
          "aud": "https://revolut.com",
          "iss": connection['iss'],
          "sub": connection['client_id']
        }
        private_key = connection['private_key'].gsub(/\\n/, "\n")
        #         jwt_token = workato.jwt_encode(
        #           jwt_body_claim, 
        #           private_key, 
        #           "RS256"
        #         )
        jwt_token = workato.jwt_encode(
          jwt_body_claim, 
          private_key,
          #           connection['private_key'], 
          "RS256"
        )

        #         .headers("Authorization": "Basic #{encoded_string}")

        response = post("#{connection['api_domain']}/auth/token").payload(
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          code: auth_code,
          grant_type: "authorization_code",
          #           client_id: connection['client_id'],
          client_assertion: jwt_token
        )
        .request_format_www_form_urlencoded

        [
          {
            # This hash is for your tokens
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          {}
        ]

      end,
      apply:
      lambda do |connection, access_token|

        case_sensitive_headers('Authorization': "Bearer #{access_token}")
        #           if current_url.include?('oauth2/token')
        #             headers('refreshing-from': 'Workato')
        #           elsif current_url.include?('s3.')
        #             headers('uploading-from': 'Workato')
        #           else

        #           end
      end,
      # TODO double check error detection
      # TODO proper error management
      detect_on: [/UNAUTHENTICATED/],
      refresh_on: [400],
      #       refresh:
      #         lambda do |connection, refresh_token|
      #           basicSecret = "#{connection['client_id']}:#{connection['client_secret']}".encode_base64
      #           payload = {
      #             grant_type: 'refresh_token',
      #             client_id: connection['client_id'],
      #             refresh_token: refresh_token,
      #           }
      #           response =
      #             post("#{connection['authorization_domain']}/oauth2/token")
      #               .headers(
      #                'refreshing-from': 'Workato',
      #                 Accept: '*/*',
      # #                 'Content-Type': 'application/x-www-form-urlencoded',
      #                 Authorization: "Basic #{basicSecret}",
      #               )
      #               .payload(payload)
      #               .request_format_www_form_urlencoded
      # #               .after_response { |code, body, headers| { code: code, body: body, headers: headers } }
      #           [
      #             {
      #               # This hash is for your tokens
      #               access_token: response['access_token'],
      #               refresh_token: response['refresh_token']
      #             },
      #           ]
      #         end,
    },
  },



  test: lambda do |_connection|
    get("https://sandbox-b2b.revolut.com/api/1.0/accounts")
  end,

  object_definitions: {
    #  Object definitions can be referenced by any input or output fields in actions/triggers.
    #  Use it to keep your code DRY. Possible arguments - connection, config_fields
    #  See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/object_definitions.html
    accounts: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            "name": "response",
            "type": "array",
            "of": "object",
            "label": "Response",
            "properties": [
              {
                "control_type": "text",
                "label": "ID",
                "type": "string",
                "name": "id"
              },
              {
                "control_type": "text",
                "label": "Name",
                "type": "string",
                "name": "name"
              },
              {
                "control_type": "number",
                "label": "Balance",
                "parse_output": "float_conversion",
                "type": "number",
                "name": "balance"
              },
              {
                "control_type": "text",
                "label": "Currency",
                "type": "string",
                "name": "currency"
              },
              {
                "control_type": "text",
                "label": "State",
                "type": "string",
                "name": "state"
              },
              {
                "control_type": "text",
                "label": "Public",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Public",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "public"
                },
                "type": "boolean",
                "name": "public"
              },
              {
                "control_type": "text",
                "label": "Created at",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "created_at"
              },
              {
                "control_type": "text",
                "label": "Updated at",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "updated_at"
              }
            ]
          }
        ]
      end
    },

    transactions: {
      fields: lambda do
        [
          {
            "name": "response",
            "type": "array",
            "of": "object",
            "label": "Response",
            "properties": [
              {
                "control_type": "text",
                "label": "ID",
                "type": "string",
                "name": "id"
              },
              {
                "control_type": "text",
                "label": "Type",
                "type": "string",
                "name": "type"
              },
              {
                "control_type": "text",
                "label": "State",
                "type": "string",
                "name": "state"
              },
              {
                "control_type": "text",
                "label": "Request ID",
                "type": "string",
                "name": "request_id"
              },
              {
                "control_type": "text",
                "label": "Created at",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "created_at"
              },
              {
                "control_type": "text",
                "label": "Updated at",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "updated_at"
              },
              {
                "control_type": "text",
                "label": "Completed at",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "completed_at"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Name",
                    "type": "string",
                    "name": "name"
                  },
                  {
                    "control_type": "text",
                    "label": "City",
                    "type": "string",
                    "name": "city"
                  },
                  {
                    "control_type": "text",
                    "label": "Category code",
                    "type": "string",
                    "name": "category_code"
                  },
                  {
                    "control_type": "text",
                    "label": "Country",
                    "type": "string",
                    "name": "country"
                  }
                ],
                "label": "Merchant",
                "type": "object",
                "name": "merchant"
              },
              {
                "name": "legs",
                "type": "array",
                "of": "object",
                "label": "Legs",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Leg ID",
                    "type": "string",
                    "name": "leg_id"
                  },
                  {
                    "control_type": "text",
                    "label": "Account ID",
                    "type": "string",
                    "name": "account_id"
                  },
                  {
                    "control_type": "number",
                    "label": "Amount",
                    "parse_output": "float_conversion",
                    "type": "number",
                    "name": "amount"
                  },
                  {
                    "control_type": "text",
                    "label": "Currency",
                    "type": "string",
                    "name": "currency"
                  },
                  {
                    "control_type": "text",
                    "label": "Description",
                    "type": "string",
                    "name": "description"
                  },
                  {
                    "control_type": "number",
                    "label": "Balance",
                    "parse_output": "float_conversion",
                    "type": "number",
                    "name": "balance"
                  }
                ]
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Card number",
                    "type": "string",
                    "name": "card_number"
                  }
                ],
                "label": "Card",
                "type": "object",
                "name": "card"
              }
            ]
          }
        ]
      end
    },

    transaction: {
      fields: lambda do
        [
  {
    "control_type": "text",
    "label": "ID",
    "type": "string",
    "name": "id"
  },
  {
    "control_type": "text",
    "label": "Type",
    "type": "string",
    "name": "type"
  },
  {
    "control_type": "text",
    "label": "State",
    "type": "string",
    "name": "state"
  },
  {
    "control_type": "text",
    "label": "Request ID",
    "type": "string",
    "name": "request_id"
  },
  {
    "control_type": "text",
    "label": "Created at",
    "render_input": "date_time_conversion",
    "parse_output": "date_time_conversion",
    "type": "date_time",
    "name": "created_at"
  },
  {
    "control_type": "text",
    "label": "Updated at",
    "render_input": "date_time_conversion",
    "parse_output": "date_time_conversion",
    "type": "date_time",
    "name": "updated_at"
  },
  {
    "control_type": "text",
    "label": "Completed at",
    "render_input": "date_time_conversion",
    "parse_output": "date_time_conversion",
    "type": "date_time",
    "name": "completed_at"
  },
  {
    "properties": [
      {
        "control_type": "text",
        "label": "Name",
        "type": "string",
        "name": "name"
      },
      {
        "control_type": "text",
        "label": "City",
        "type": "string",
        "name": "city"
      },
      {
        "control_type": "text",
        "label": "Category code",
        "type": "string",
        "name": "category_code"
      },
      {
        "control_type": "text",
        "label": "Country",
        "type": "string",
        "name": "country"
      }
    ],
    "label": "Merchant",
    "type": "object",
    "name": "merchant"
  },
  {
    "name": "legs",
    "type": "array",
    "of": "object",
    "label": "Legs",
    "properties": [
      {
        "control_type": "text",
        "label": "Leg ID",
        "type": "string",
        "name": "leg_id"
      },
      {
        "control_type": "text",
        "label": "Account ID",
        "type": "string",
        "name": "account_id"
      },
      {
        "control_type": "number",
        "label": "Amount",
        "parse_output": "float_conversion",
        "type": "number",
        "name": "amount"
      },
      {
        "control_type": "text",
        "label": "Currency",
        "type": "string",
        "name": "currency"
      },
      {
        "control_type": "text",
        "label": "Description",
        "type": "string",
        "name": "description"
      },
      {
        "control_type": "number",
        "label": "Balance",
        "parse_output": "float_conversion",
        "type": "number",
        "name": "balance"
      }
    ]
  },
  {
    "properties": [
      {
        "control_type": "text",
        "label": "Card number",
        "type": "string",
        "name": "card_number"
      }
    ],
    "label": "Card",
    "type": "object",
    "name": "card"
  }
]
      end
    }
  },

  # This implements a standard custom action for your users to unblock themselves even when no actions exist.
  # See more at https://docs.workato.com/developing-connectors/sdk/guides/building-actions/custom-action.html
  custom_action: true,

  custom_action_help: {
    learn_more_url: "https://developer.calendly.com/api-docs/YXBpOjM5NQ-calendly-api",
    learn_more_text: "Calendly documentation",
    body: "<p>Build your own Calendly action with a HTTP request. The request will be authorized with your Calendly Hana connection.</p>"
  },

  actions: {
    get_accounts: {
      # Define the way people search for your actions and how it looks like on the recipe level
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html
      title: "Get Accounts",


      # The input fields shown for this action. Shows when a user is defining the action.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#input-fields
      input_fields: lambda do |object_definitions|
      end,

      # This code is run when a recipe uses this action.
      # Possible arguements in this specific order - connection, input, input_schema, output_schema
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#execute
      execute: lambda do |_connection, _input, _input_schema, _output_schema|
        {
          response: get("/api/1.0/accounts")
        }

      end,

      # The output values of the action. Shows in the output datatree of a recipe.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#output-fields
      output_fields: lambda do |object_definitions|
        object_definitions["accounts"]
      end,

      # Provides you with a preview of possible output values in your datatree.
      # Possible arguements in this specific order - connection, input
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#sample-output
      sample_output: lambda do |_connection, _input|

      end
    },
    get_transactions: {
      # Define the way people search for your actions and how it looks like on the recipe level
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html
      title: "Get Transactions",


      # The input fields shown for this action. Shows when a user is defining the action.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#input-fields
      input_fields: lambda do |object_definitions|
      end,

      # This code is run when a recipe uses this action.
      # Possible arguements in this specific order - connection, input, input_schema, output_schema
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#execute
      execute: lambda do |_connection, _input, _input_schema, _output_schema|
        {
          response: get("/api/1.0/transactions")
        }
      end,

      # The output values of the action. Shows in the output datatree of a recipe.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#output-fields
      output_fields: lambda do |object_definitions|
        object_definitions["transactions"]
      end,

      # Provides you with a preview of possible output values in your datatree.
      # Possible arguements in this specific order - connection, input
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#sample-output
      sample_output: lambda do |_connection, _input|

      end
    },
    get_transactions_id: {
      # Define the way people search for your actions and how it looks like on the recipe level
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html
      title: "Get Transactions by ID",


      # The input fields shown for this action. Shows when a user is defining the action.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#input-fields
      input_fields: lambda do |object_definitions|
        [
          {name: 'transactionid'}
        ]
      end,

      # This code is run when a recipe uses this action.
      # Possible arguements in this specific order - connection, input, input_schema, output_schema
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#execute
      execute: lambda do |_connection, input, _input_schema, _output_schema|
        
        get("/api/1.0/transaction/#{input['transactionid']}")
     
      end,

      # The output values of the action. Shows in the output datatree of a recipe.
      # Possible arguements in this specific order - object_definitions
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#output-fields
      output_fields: lambda do |object_definitions|
        object_definitions["transaction"]
      end,

      # Provides you with a preview of possible output values in your datatree.
      # Possible arguements in this specific order - connection, input
      # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#sample-output
      sample_output: lambda do |_connection, _input|

      end
    }
  },

  triggers: {
    # Dynamic webhook example. Subscribes and unsubscribes webhooks programatically
    # see more at https://docs.workato.com/developing-connectors/sdk/guides/building-triggers/dynamic-webhook.html

    #  Polling trigger example. Checks for new records every 5 minutes
    #  see more at https://docs.workato.com/developing-connectors/sdk/guides/building-triggers/poll.html
    #  updated_ticket: {
    #    input_fields: lambda do
    #      [
    #        {
    #          name: 'since',
    #          type: :timestamp,
    #          optional: false
    #        }
    #      ]
    #    end,

    #    poll: lambda do |connection, input, last_updated_since|
    #      page_size = 100
    #      updated_since = (last_updated_since || input['since']).to_time.utc.iso8601

    #      tickets = get("https://#{connection['helpdesk']}.freshdesk.com/api/v2/tickets.json").
    #                params(order_by: 'updated_at',
    #                       order_type: 'asc',
    #                       per_page: page_size,
    #                       updated_since: updated_since)

    #      next_updated_since = tickets.last['updated_at'] unless tickets.blank?

    #      {
    #        events: tickets,
    #        next_poll: next_updated_since,
    #        can_poll_more: tickets.length >= page_size
    #      }
    #    end,

    #    dedup: lambda do |event|
    #      event['id']
    #    end,

    #    output_fields: lambda do |object_definitions|
    #      object_definitions['ticket']
    #    end
    #  },

  },

  pick_lists: {
    # Picklists can be referenced by inputs fields or object_definitions
    # possible arguements - connection
    # see more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/picklists.html
    event_type: lambda do
      [
        # Display name, value
        %W[Event\ Created invitee.created],
        %W[Event\ Canceled invitee.canceled],
        %W[All\ Events all]
      ]
    end

    # folder: lambda do |connection|
    #   get("https://www.wrike.com/api/v3/folders")["data"].
    #     map { |folder| [folder["title"], folder["id"]] }
    # end
  },

  # Reusable methods can be called from object_definitions, picklists or actions
  # See more at https://docs.workato.com/developing-connectors/sdk/sdk-reference/methods.html
  methods: {
  }
}
