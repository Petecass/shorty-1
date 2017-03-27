# frozen_string_literal: true
require File.expand_path '../spec_helper.rb', __FILE__

describe 'My Sinatra Application' do
  let!(:redis) { Redis.new }
  let(:body) { JSON.parse(last_response.body) }

  describe '#POST /shorten' do
    context 'with valid params' do
      let(:params) { { shortcode: 'shorty', url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params
        body = JSON.parse(last_response.body)
        expect(last_response.content_type).to eq 'application/json'
        expect(body['shortcode']).to eq params[:shortcode]
        expect(last_response.status).to eq 201
      end

      it 'saves url to db' do
        expect(Url).to receive(:create)
        post '/shorten', params
      end
    end

    context 'when shortcode is not present' do
      let(:params) { { shortcode: '', url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 201
        expect(Url.find(body['shortcode']).url).to eq params[:url]
      end
    end

    context 'when shortcode is nil' do
      let(:params) { { url: 'http://example.com' } }

      it 'returns 201' do
        post '/shorten', params
        expect(last_response.content_type).to eq 'application/json'
        expect(Url.find(body['shortcode']).url).to eq params[:url]
        expect(last_response.status).to eq 201
      end
    end

    context 'when url is blank' do
      let(:params) { { shortcode: 'shorty', url: '' } }
      before(:each) do
        post '/shorten', params
      end

      it 'returns 400' do
        # body = JSON.parse(last_response.body)
        # expect(body['error']).to eq 'Url is not valid'
        expect(last_response.content_type).to eq 'application/json'
        expect(last_response.status).to eq 400
      end
    end

    context 'when url is nil' do
      let(:params) { { shortcode: 'shorty' } }
      before(:each) do
        post '/shorten', params
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
        post '/shorten', params
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'The desired shortcode is already in use'
        expect(last_response.status).to eq 409
      end
    end

    context 'when shortcode does not match regex' do
      let(:params) { { shortcode: '$%qwerty', url: 'http://example.com' } }
      before(:each) do
        post '/shorten', params
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
      before(:each) do
        Url.create(params)
        get "/#{params[:shortcode]}"
      end

      it 'returns 302' do
        expect(last_response.status).to eq 302
        expect(last_response.location).to eq params[:url]
      end
    end

    context 'when shortcode does not exist' do
      it 'returns 404' do
        get '/wookie'
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
        get "/#{params[:shortcode]}/stats"
      end

      it 'returns 200' do
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
          get "/#{params[:shortcode]}/stats"
          expect(body['startDate']).to eq url.start_date
          expect(body['redirectCount']).to eq url.redirect_count
          expect(body['lastSeenDate']).to eq url.last_seen_date
        end
      end
    end

    context 'when shortcode does not exist' do
      it 'returns 404' do
        get '/wookie/stats'
        expect(last_response.content_type).to eq 'application/json'
        expect(body['error']).to eq 'Shortcode not found'
        expect(last_response.status).to eq 404
      end
    end
  end
end
