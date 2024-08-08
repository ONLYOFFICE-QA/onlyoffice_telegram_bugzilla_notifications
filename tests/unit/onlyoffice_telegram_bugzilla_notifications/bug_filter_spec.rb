# frozen_string_literal: true

require 'rspec'
require_relative '../../../lib/onlyoffice_telegram_bugzilla_notifications/bug_filter'

describe OnlyofficeTelegramBugzillaNotifications::BugFilter do
  subject(:filter) { described_class.new(bugzilla, config, bug_id) }

  let(:bug_id) { 12_345 }
  let(:bugzilla) { double('OnlyofficeBugzillaHelper', bug_data: bug_info) }

  context 'when the product matches the filter' do
    let(:bug_info) { { 'product' => 'TestProduct' } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns true' do
      expect(filter.check_all).to be(true)
    end
  end

  context 'when the product does not match the filter' do
    let(:bug_info) { { 'product' => 'AnotherProduct' } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns false' do
      expect(filter.check_all).to be(false)
    end
  end

  context 'when no products are specified in the config' do
    let(:bug_info) { { 'product' => 'TestProduct' } }
    let(:config) { {} }

    it 'returns true' do
      expect(filter.check_all).to be(true)
    end
  end

  context 'when the bug has no product' do
    let(:bug_info) { { 'product' => nil } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns true' do
      expect(filter.check_all).to be(true)
    end
  end
end
