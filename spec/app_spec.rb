# frozen_string_literal: true
# rubocop:disable Style/BlockDelimiters

require File.expand_path '../spec_helper.rb', __FILE__

describe 'My Sinatra Application' do
  let!(:redis) { Redis.new }
  let(:body) { JSON.parse(last_response.body) }
  let(:headers) { { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' } }

  describe '#POST /shorten' do
    context 'with valid params' do
      let(:params) { { shortcode: 'shorty', url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params.to_json, headers
        body = JSON.parse(last_response.body)
        expect(last_response.content_type).to eq 'application/json'
        expect(body['shortcode']).to eq params[:shortcode]
        expect(last_response.status).to eq 201
      end

      it 'saves url to db' do
        expect(Url).to receive(:create)
        post '/shorten', params.to_json, headers
      end
    end

    context 'when shortcode is not present' do
      let(:params) { { shortcode: '', url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params.to_json, headers
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 201
        expect(Url.find(body['shortcode']).url).to eq params[:url]
      end
    end

    context 'when shortcode is nil' do
      let(:params) { { url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params.to_json, headers
        expect(last_response.content_type).to eq 'application/json'
        expect(Url.find(body['shortcode']).url).to eq params[:url]
        expect(last_response.status).to eq 201
      end
    end

    context 'when url is blank' do
      let(:params) { { shortcode: 'shorty', url: '' } }

      before(:each) do
        post '/shorten', params.to_json, headers
      end

      it 'returns 400' do
        expect(body['error']).to eq 'no url present'
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 400
      end
    end

    context 'when url is nil' do
      let(:params) { { shortcode: 'shorty' } }
      before(:each) do
        post '/shorten', params.to_json, headers
      end

      it 'returns 400' do
        expect(body['error']).to eq 'no url present'
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 400
      end
    end

    context 'when shortcode is in use' do
      let(:params) { { shortcode: 'shorty', url: 'http://example.com' } }
      before(:each) do
      end

      it 'returns 409' do
        Url.create(params)
        post '/shorten', params.to_json, headers
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'The desired shortcode is already in use'
        expect(last_response.status).to eq 409
      end
    end

    context 'when shortcode does not match regex' do
      let(:params) { { shortcode: '$%qwerty', url: 'http://example.com' } }
      before(:each) do
        post '/shorten', params.to_json, headers
      end

      it 'returns 422' do
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'Shortcode not valid'
        expect(last_response.status).to eq 422
      end
    end
  end

  describe '#GET /:shortcode' do
    context 'when shortcode is present' do
      let(:params) { { shortcode: 'shorty', url: 'http://example.com' } }
      let!(:url) { Url.create(params) }

      it 'returns 302' do
        get "/#{params[:shortcode]}", headers
        expect(last_response.status).to eq 302
        expect(last_response.location).to eq params[:url]
      end

      it 'updates redirect_count' do
        expect {
          get "/#{params[:shortcode]}", headers
        }.to change {
          Url.find(url.shortcode).redirect_count
        }.by 1
      end

      it 'updates last seen date' do
        get "/#{params[:shortcode]}", headers
        new_time = Time.new(2030, 11, 1, 15, 25, 0, '+09:00').iso8601
        Timecop.freeze(new_time) do
          expect(Url.find(url.shortcode).last_seen_date).to eq new_time
        end
      end
    end

    context 'when shortcode does not exist' do
      it 'returns 404' do
        get '/wookie', headers
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'Shortcode not found'
        expect(last_response.status).to eq 404
      end
    end
  end

  describe '#GET /:shortcode/stats' do
    context 'when shortcode exists' do
      let(:params) { { shortcode: 'shorty', url: 'http://example.com' } }
      let!(:url) { Url.create(params) }

      before(:each) do
        get "/#{params[:shortcode]}/stats", headers
      end

      it 'returns 200' do
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 200
      end

      it 'returns the startDate and redirectCount' do
        expect(body['startDate']).to eq url.start_date
        expect(body['redirectCount']).to eq url.redirect_count
        expect(body['lastSeenDate']).to be_nil
      end

      context 'when redirectCount is present' do
        let(:params) { { shortcode: 'wookie', url: 'https://example', redirectCount: 3 } }
        it 'displays lastSeenDate' do
          url = Url.create(params)
          get "/#{params[:shortcode]}/stats", headers
          expect(body['startDate']).to eq url.start_date
          expect(body['redirectCount']).to eq url.redirect_count
          expect(body['lastSeenDate']).to eq url.last_seen_date
        end
      end
    end

    context 'when shortcode does not exist' do
      it 'returns 404' do
        get '/wookie/stats', headers
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'Shortcode not found'
        expect(last_response.status).to eq 404
      end
    end
  end
end
