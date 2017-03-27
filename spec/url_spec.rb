# frozen_string_literal: true
require File.expand_path '../spec_helper.rb', __FILE__

describe Url do
  let!(:redis) { Redis.new }
  describe '#create' do
    context 'with valid params' do
      let(:params) { { shortcode: 'shorty', url: 'https://example' } }
      let(:url) { Url.create(params) }

      it 'instatiates the object ' do
        expect(url.shortcode).to eq params[:shortcode]
        expect(url.url).to eq params[:url]
        expect(url.start_date).to eq Time.now.iso8601.to_s
      end

      it 'saves object to redis' do
        url
        record = JSON.parse(redis.get(params[:shortcode]))
        expect(record['shortcode']).to eq params[:shortcode]
        expect(record['url']).to eq params[:url]
        expect(record['startDate']).to eq Time.now.iso8601.to_s
      end
    end

    context 'with no shortcode' do
      let(:params) { { shortcode: '', url: 'https://example' } }
      let(:url) { Url.create(params) }

      it 'generates a shortcode' do
        expect(url.shortcode).to match /^[0-9a-zA-Z_]{6}$/
        expect(url.url).to eq params[:url]
      end

      it 'saves object to db' do
        url
        record = JSON.parse(redis.get(url.shortcode))
        expect(record['shortcode']).to eq url.shortcode
        expect(record['url']).to eq params[:url]
        expect(record['startDate']).to eq Time.now.iso8601.to_s
      end
    end

    context 'without valid params' do
      let(:params) { { shortcode: 'shorty', url: '' } }
      it 'returns false' do
        expect(Url.create(params)).to eq false
      end
    end
  end

  describe '#find' do
    let(:data) do
      { shortcode: 'shorty',
        url: 'someurl.com',
        startDate: Time.now.iso8601,
        lastSeenDate: Time.now.iso8601,
        redirectCount: 0 }
    end

    context 'with valid params' do
      it 'finds the object' do
        redis.set(data[:shortcode], data.to_json)
        url = Url.find(data[:shortcode])
        expect(url.shortcode).to eq data[:shortcode]
        expect(url.url).to eq data[:url]
      end

    end

    context "when record doesn't exist" do
      it 'finds the object' do
        url = Url.find('wookie')
        expect(url).to be_nil
      end
    end
  end

  describe '#update' do
    let(:data) do
      { shortcode: 'shorty',
        url: 'someurl.com',
        startDate: Time.now.iso8601,
        lastSeenDate: Time.now.iso8601,
        redirectCount: 0 }
    end

    let!(:current_url) { redis.set(data[:shortcode], data.to_json) }

    it 'updates attribute on db' do
      url = Url.find(data[:shortcode])
      url.update(redirect_count: 3)
      expect(url.redirect_count).to eq 3
      db_record = JSON.parse(redis.get(data[:shortcode]))
      expect(db_record['redirect_count']).to eq 3
    end
  end
end
