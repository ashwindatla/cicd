{
  title: 'Akeneo 2nd',
  connection: {
    fields: [

      {
        name: 'client_id',
        control_type: :text,
        label: 'Client ID',
        hint: 'Identifier of the Oauth client.',
        optional: 'false',
      },
      {
        name: 'client_secret',
        label: 'Client secret',
        hint: 'Secret of the Oauth client.',
        optional: 'false',
        control_type: 'password',
      },
      {
        name: 'username',
        control_type: :text,
        label: 'Username',
        optional: 'false'
      },
      {
        name: 'password',
        control_type: 'password',
        label: 'Password',
        optional: 'false'
      }
    ],

    authorization: {
      type: 'custom_auth', #Set to custom_auth

      acquire: lambda do |connection|
        hash = ("#{connection['client_id']}:#{connection['client_secret']}").
          encode_base64
        # Token URL
        response = post('http://workato.demo.cloud.akeneo.com/api/oauth/v1/token'). 
        payload(grant_type: "password",
          username: connection['username'],
          password: connection['password']).
          case_sensitive_headers(Authorization: "Basic #{[hash]}").
          request_format_www_form_urlencoded.follow_redirection

        {
          access_token: response["access_token"],
          refresh_token: response["refresh_token"]
        }
      end,

      detect_on: [401, 403],

      refresh_on: [401, 403],
      refresh:
        lambda do |connection, refresh_token|
          hash = "#{connection['client_id']}:#{connection['client_secret']}".encode_base64
          payload = {
            grant_type: 'refresh_token',
            refresh_token: refresh_token
          }
          response =
            post("http://workato.demo.cloud.akeneo.com/api/oauth/v1/token")
              .headers(
                Accept: '*/*',
#                 'Content-Type': 'application/x-www-form-urlencoded',
                Authorization: "Basic #{hash}",
              )
              .payload(payload)
              .request_format_www_form_urlencoded
#               .after_response { |code, body, headers| { code: code, body: body, headers: headers } }
          [
            {
              # This hash is for your tokens
              access_token: response['access_token'],
              refresh_token: response['refresh_token']
            },
          ]
        end,

      apply: lambda do |connection|
        headers("Authorization": "Bearer #{connection['access_token']}")
      end
    },

    base_uri: lambda do
      "https://demo.akeneo.com"
    end,

  },

  test: lambda do |connection|
    get('http://workato.demo.cloud.akeneo.com/api/rest/v1/families').follow_redirection
  end,
  methods: {},
  actions: {
    get_all_products: {
      title: 'Get a list of product',
      description: 'This endpoint allows you to get a list of products. Products are paginated and they can be filtered.',

      
      execute:
      lambda do |connection, _input, _input_schema, _output_schema|
        get('http://workato.demo.cloud.akeneo.com/api/rest/v1/products').follow_redirection
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["product"]
      end,
    },
    create_product: {
      title: 'Create a product',
      description: 'This endpoint allows you to get a list of products. Products are paginated and they can be filtered.',
      
      input_fields: lambda do |object_definitions|
        [
          {
            "control_type": "text",
            "label": "Identifier",
            "type": "string",
            "name": "identifier"
          },
          {
            "control_type": "text",
            "label": "Enabled",
            "render_input": {},
            "parse_output": {},
            "toggle_hint": "Select from option list",
            "toggle_field": {
              "label": "Enabled",
              "control_type": "text",
              "toggle_hint": "Use custom value",
              "type": "boolean",
              "name": "enabled"
            },
            "type": "boolean",
            "name": "enabled"
          },
          {
            "control_type": "text",
            "label": "Family",
            "type": "string",
            "name": "family"
          },
          {
            "name": "categories",
            "type": "array",
            "of": "string",
            "control_type": "text",
            "label": "Categories"
          },
          {
            "control_type": "text",
            "label": "Parent",
            "type": "string",
            "name": "parent"
          },
          {
            "properties": [
              {
                "name": "name",
                "type": "array",
                "of": "object",
                "label": "Name",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Data",
                    "type": "string",
                    "name": "data"
                  },
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  }
                ]
              },
              {
                "name": "description",
                "type": "array",
                "of": "object",
                "label": "Description",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Data",
                    "type": "string",
                    "name": "data"
                  },
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  }
                ]
              },
              {
                "name": "price",
                "type": "array",
                "of": "object",
                "label": "Price",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  },
                  {
                    "name": "data",
                    "type": "array",
                    "of": "object",
                    "label": "Data",
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Amount",
                        "type": "string",
                        "name": "amount"
                      },
                      {
                        "control_type": "text",
                        "label": "Currency",
                        "type": "string",
                        "name": "currency"
                      }
                    ]
                  }
                ]
              },
              {
                "name": "color",
                "type": "array",
                "of": "object",
                "label": "Color",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  },
                  {
                    "control_type": "text",
                    "label": "Data",
                    "type": "string",
                    "name": "data"
                  },
                  {
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Attribute",
                        "type": "string",
                        "name": "attribute"
                      },
                      {
                        "control_type": "text",
                        "label": "Code",
                        "type": "string",
                        "name": "code"
                      },
                      {
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "En US",
                            "type": "string",
                            "name": "en_US"
                          },
                          {
                            "control_type": "text",
                            "label": "Fr FR",
                            "type": "string",
                            "name": "fr_FR"
                          }
                        ],
                        "label": "Labels",
                        "type": "object",
                        "name": "labels"
                      }
                    ],
                    "label": "Linked data",
                    "type": "object",
                    "name": "linked_data"
                  }
                ]
              },
              {
                "name": "size",
                "type": "array",
                "of": "object",
                "label": "Size",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  },
                  {
                    "control_type": "text",
                    "label": "Data",
                    "type": "string",
                    "name": "data"
                  },
                  {
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Attribute",
                        "type": "string",
                        "name": "attribute"
                      },
                      {
                        "control_type": "text",
                        "label": "Code",
                        "type": "string",
                        "name": "code"
                      },
                      {
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "En US",
                            "type": "string",
                            "name": "en_US"
                          },
                          {
                            "control_type": "text",
                            "label": "Fr FR",
                            "type": "string",
                            "name": "fr_FR"
                          }
                        ],
                        "label": "Labels",
                        "type": "object",
                        "name": "labels"
                      }
                    ],
                    "label": "Linked data",
                    "type": "object",
                    "name": "linked_data"
                  }
                ]
              },
              {
                "name": "collection",
                "type": "array",
                "of": "object",
                "label": "Collection",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Locale",
                    "type": "string",
                    "name": "locale"
                  },
                  {
                    "control_type": "text",
                    "label": "Scope",
                    "type": "string",
                    "name": "scope"
                  },
                  {
                    "name": "data",
                    "type": "array",
                    "of": "string",
                    "control_type": "text",
                    "label": "Data"
                  },
                  {
                    "properties": [
                      {
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Attribute",
                            "type": "string",
                            "name": "attribute"
                          },
                          {
                            "control_type": "text",
                            "label": "Code",
                            "type": "string",
                            "name": "code"
                          },
                          {
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "En US",
                                "type": "string",
                                "name": "en_US"
                              },
                              {
                                "control_type": "text",
                                "label": "Fr FR",
                                "type": "string",
                                "name": "fr_FR"
                              }
                            ],
                            "label": "Labels",
                            "type": "object",
                            "name": "labels"
                          }
                        ],
                        "label": "Winter 2016",
                        "type": "object",
                        "name": "winter_2016"
                      }
                    ],
                    "label": "Linked data",
                    "type": "object",
                    "name": "linked_data"
                  }
                ]
              }
            ],
            "label": "Values",
            "type": "object",
            "name": "values"
          },
          {
            "properties": [
              {
                "properties": [
                  {
                    "name": "products",
                    "type": "array",
                    "of": "string",
                    "control_type": "text",
                    "label": "Products"
                  }
                ],
                "label": "PACK",
                "type": "object",
                "name": "PACK"
              }
            ],
            "label": "Associations",
            "type": "object",
            "name": "associations"
          },
          {
            "properties": [
              {
                "properties": [
                  {
                    "name": "products",
                    "type": "array",
                    "of": "object",
                    "label": "Products",
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Identifier",
                        "type": "string",
                        "name": "identifier"
                      },
                      {
                        "control_type": "number",
                        "label": "Quantity",
                        "parse_output": "float_conversion",
                        "type": "number",
                        "name": "quantity"
                      }
                    ]
                  },
                  {
                    "name": "product_models",
                    "type": "array",
                    "of": "object",
                    "label": "Product models",
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Identifier",
                        "type": "string",
                        "name": "identifier"
                      },
                      {
                        "control_type": "number",
                        "label": "Quantity",
                        "parse_output": "float_conversion",
                        "type": "number",
                        "name": "quantity"
                      }
                    ]
                  }
                ],
                "label": "PRODUCT SET",
                "type": "object",
                "name": "PRODUCT_SET"
              }
            ],
            "label": "Quantified associations",
            "type": "object",
            "name": "quantified_associations"
          }
        ]
      end,
      execute:
      lambda do |connection, input, _input_schema, _output_schema|
        post('http://workato.demo.cloud.akeneo.com/api/rest/v1/products', input).follow_redirection
      end,
      output_fields: lambda do |object_definitions|
#         object_definitions["product"]
      end,
    }
  },

  # triggers:
  # document uploaded
  # document updated

  # Object definitions
  object_definitions: {
    product: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            "properties": [
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Href",
                    "type": "string",
                    "name": "href"
                  }
                ],
                "label": "Self",
                "type": "object",
                "name": "self"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Href",
                    "type": "string",
                    "name": "href"
                  }
                ],
                "label": "First",
                "type": "object",
                "name": "first"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Href",
                    "type": "string",
                    "name": "href"
                  }
                ],
                "label": "Previous",
                "type": "object",
                "name": "previous"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Href",
                    "type": "string",
                    "name": "href"
                  }
                ],
                "label": "Next",
                "type": "object",
                "name": "next"
              }
            ],
            "label": "Links",
            "type": "object",
            "name": "_links"
          },
          {
            "control_type": "number",
            "label": "Current page",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "current_page"
          },
          {
            "properties": [
              {
                "name": "items",
                "type": "array",
                "of": "object",
                "label": "Items",
                "properties": [
                  {
                    "properties": [
                      {
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Href",
                            "type": "string",
                            "name": "href"
                          }
                        ],
                        "label": "Self",
                        "type": "object",
                        "name": "self"
                      }
                    ],
                    "label": "Links",
                    "type": "object",
                    "name": "_links"
                  },
                  {
                    "control_type": "text",
                    "label": "Uuid",
                    "type": "string",
                    "name": "uuid"
                  },
                  {
                    "control_type": "text",
                    "label": "Identifier",
                    "type": "string",
                    "name": "identifier"
                  },
                  {
                    "control_type": "text",
                    "label": "Family",
                    "type": "string",
                    "name": "family"
                  },
                  {
                    "control_type": "text",
                    "label": "Parent",
                    "type": "string",
                    "name": "parent"
                  },
                  {
                    "name": "categories",
                    "type": "array",
                    "of": "string",
                    "control_type": "text",
                    "label": "Categories"
                  },
                  {
                    "control_type": "text",
                    "label": "Enabled",
                    "render_input": {},
                    "parse_output": {},
                    "toggle_hint": "Select from option list",
                    "toggle_field": {
                      "label": "Enabled",
                      "control_type": "text",
                      "toggle_hint": "Use custom value",
                      "type": "boolean",
                      "name": "enabled"
                    },
                    "type": "boolean",
                    "name": "enabled"
                  },
                  {
                    "properties": [
                      {
                        "name": "name",
                        "type": "array",
                        "of": "object",
                        "label": "Name",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Data",
                            "type": "string",
                            "name": "data"
                          },
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          }
                        ]
                      },
                      {
                        "name": "description",
                        "type": "array",
                        "of": "object",
                        "label": "Description",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Data",
                            "type": "string",
                            "name": "data"
                          },
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          }
                        ]
                      },
                      {
                        "name": "price",
                        "type": "array",
                        "of": "object",
                        "label": "Price",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          },
                          {
                            "name": "data",
                            "type": "array",
                            "of": "object",
                            "label": "Data",
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "Amount",
                                "type": "string",
                                "name": "amount"
                              },
                              {
                                "control_type": "text",
                                "label": "Currency",
                                "type": "string",
                                "name": "currency"
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "name": "color",
                        "type": "array",
                        "of": "object",
                        "label": "Color",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          },
                          {
                            "control_type": "text",
                            "label": "Data",
                            "type": "string",
                            "name": "data"
                          },
                          {
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "Attribute",
                                "type": "string",
                                "name": "attribute"
                              },
                              {
                                "control_type": "text",
                                "label": "Code",
                                "type": "string",
                                "name": "code"
                              },
                              {
                                "properties": [
                                  {
                                    "control_type": "text",
                                    "label": "En US",
                                    "type": "string",
                                    "name": "en_US"
                                  },
                                  {
                                    "control_type": "text",
                                    "label": "Fr FR",
                                    "type": "string",
                                    "name": "fr_FR"
                                  }
                                ],
                                "label": "Labels",
                                "type": "object",
                                "name": "labels"
                              }
                            ],
                            "label": "Linked data",
                            "type": "object",
                            "name": "linked_data"
                          }
                        ]
                      },
                      {
                        "name": "size",
                        "type": "array",
                        "of": "object",
                        "label": "Size",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          },
                          {
                            "control_type": "text",
                            "label": "Data",
                            "type": "string",
                            "name": "data"
                          },
                          {
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "Attribute",
                                "type": "string",
                                "name": "attribute"
                              },
                              {
                                "control_type": "text",
                                "label": "Code",
                                "type": "string",
                                "name": "code"
                              },
                              {
                                "properties": [
                                  {
                                    "control_type": "text",
                                    "label": "En US",
                                    "type": "string",
                                    "name": "en_US"
                                  },
                                  {
                                    "control_type": "text",
                                    "label": "Fr FR",
                                    "type": "string",
                                    "name": "fr_FR"
                                  }
                                ],
                                "label": "Labels",
                                "type": "object",
                                "name": "labels"
                              }
                            ],
                            "label": "Linked data",
                            "type": "object",
                            "name": "linked_data"
                          }
                        ]
                      },
                      {
                        "name": "collection",
                        "type": "array",
                        "of": "object",
                        "label": "Collection",
                        "properties": [
                          {
                            "control_type": "text",
                            "label": "Locale",
                            "type": "string",
                            "name": "locale"
                          },
                          {
                            "control_type": "text",
                            "label": "Scope",
                            "type": "string",
                            "name": "scope"
                          },
                          {
                            "name": "data",
                            "type": "array",
                            "of": "string",
                            "control_type": "text",
                            "label": "Data"
                          },
                          {
                            "properties": [
                              {
                                "properties": [
                                  {
                                    "control_type": "text",
                                    "label": "Attribute",
                                    "type": "string",
                                    "name": "attribute"
                                  },
                                  {
                                    "control_type": "text",
                                    "label": "Code",
                                    "type": "string",
                                    "name": "code"
                                  },
                                  {
                                    "properties": [
                                      {
                                        "control_type": "text",
                                        "label": "En US",
                                        "type": "string",
                                        "name": "en_US"
                                      },
                                      {
                                        "control_type": "text",
                                        "label": "Fr FR",
                                        "type": "string",
                                        "name": "fr_FR"
                                      }
                                    ],
                                    "label": "Labels",
                                    "type": "object",
                                    "name": "labels"
                                  }
                                ],
                                "label": "Winter 2016",
                                "type": "object",
                                "name": "winter_2016"
                              }
                            ],
                            "label": "Linked data",
                            "type": "object",
                            "name": "linked_data"
                          }
                        ]
                      }
                    ],
                    "label": "Values",
                    "type": "object",
                    "name": "values"
                  },
                  {
                    "control_type": "text",
                    "label": "Created",
                    "render_input": "date_time_conversion",
                    "parse_output": "date_time_conversion",
                    "type": "date_time",
                    "name": "created"
                  },
                  {
                    "control_type": "text",
                    "label": "Updated",
                    "render_input": "date_time_conversion",
                    "parse_output": "date_time_conversion",
                    "type": "date_time",
                    "name": "updated"
                  },
                  {
                    "properties": [
                      {
                        "properties": [
                          {
                            "name": "products",
                            "type": "array",
                            "of": "string",
                            "control_type": "text",
                            "label": "Products"
                          }
                        ],
                        "label": "PACK",
                        "type": "object",
                        "name": "PACK"
                      }
                    ],
                    "label": "Associations",
                    "type": "object",
                    "name": "associations"
                  },
                  {
                    "properties": [
                      {
                        "properties": [
                          {
                            "name": "products",
                            "type": "array",
                            "of": "object",
                            "label": "Products",
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "Identifier",
                                "type": "string",
                                "name": "identifier"
                              },
                              {
                                "control_type": "number",
                                "label": "Quantity",
                                "parse_output": "float_conversion",
                                "type": "number",
                                "name": "quantity"
                              }
                            ]
                          },
                          {
                            "name": "product_models",
                            "type": "array",
                            "of": "object",
                            "label": "Product models",
                            "properties": [
                              {
                                "control_type": "text",
                                "label": "Identifier",
                                "type": "string",
                                "name": "identifier"
                              },
                              {
                                "control_type": "number",
                                "label": "Quantity",
                                "parse_output": "float_conversion",
                                "type": "number",
                                "name": "quantity"
                              }
                            ]
                          }
                        ],
                        "label": "PRODUCT SET",
                        "type": "object",
                        "name": "PRODUCT_SET"
                      }
                    ],
                    "label": "Quantified associations",
                    "type": "object",
                    "name": "quantified_associations"
                  },
                  {
                    "name": "quality_scores",
                    "type": "array",
                    "of": "object",
                    "label": "Quality scores",
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Scope",
                        "type": "string",
                        "name": "scope"
                      },
                      {
                        "control_type": "text",
                        "label": "Locale",
                        "type": "string",
                        "name": "locale"
                      },
                      {
                        "control_type": "text",
                        "label": "Data",
                        "type": "string",
                        "name": "data"
                      }
                    ]
                  },
                  {
                    "name": "completenesses",
                    "type": "array",
                    "of": "object",
                    "label": "Completenesses",
                    "properties": [
                      {
                        "control_type": "text",
                        "label": "Scope",
                        "type": "string",
                        "name": "scope"
                      },
                      {
                        "control_type": "text",
                        "label": "Locale",
                        "type": "string",
                        "name": "locale"
                      },
                      {
                        "control_type": "number",
                        "label": "Data",
                        "parse_output": "float_conversion",
                        "type": "number",
                        "name": "data"
                      }
                    ]
                  }
                ]
              }
            ],
            "label": "Embedded",
            "type": "object",
            "name": "_embedded"
          }
        ]
      end
    },
    search_document: {
      fields: lambda do |_connection, _config_fields, object_definitions|
        [
          { name: 'edges', label: 'Assets', type: 'array', of: 'object',
            properties: object_definitions["document"] },
          { name: 'pageInfo' },
          { name: 'aggregate' }
        ]
      end
    }
  }
}
