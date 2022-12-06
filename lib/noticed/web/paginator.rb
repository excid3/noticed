# frozen_string_literal: true

module Noticed
  # This is not a public API
  class Paginator
    DEFAULT = { page: 1, per_page: 10 }.freeze

    attr_reader :page, :per_page, :total_pages, :count

    def initialize(collection, params = {})
      @count    = collection.size
      @page     = (params[:page] || DEFAULT[:page]).to_i
      @per_page = params[:per_page] || DEFAULT[:per_page]
    end

    def self.paginate(collection, params = {})
      paginator = new(collection, params)
      [paginator, collection.offset(paginator.offset).limit(paginator.per_page)]
    end

    def first
      page * per_page - per_page + 1
    end

    def last
      return count if last_page?

      page * per_page
    end

    def offset
      return 0 if page == 1

      per_page * (page.to_i - 1)
    end

    def next_page
      page + 1 unless last_page?
    end

    def next_page?
      page < total_pages
    end

    def previous_page
      page - 1 unless first_page?
    end

    def previous_page?
      page > 1
    end

    def last_page?
      page == total_pages
    end

    def first_page?
      page == 1
    end

    def total_pages
      (count / per_page.to_f).ceil
    end
  end
end