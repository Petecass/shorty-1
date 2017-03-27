require File.expand_path '../spec_helper.rb', __FILE__

describe 'My Sinatra Application' do
  it 'should return hello world' do
    get '/'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq 'Hello World'
  end
end
