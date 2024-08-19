# frozen_string_literal: true

require 'rspec'
require_relative '../../../lib/onlyoffice_telegram_bugzilla_notifications/bug_filter'

describe OnlyofficeTelegramBugzillaNotifications::BugFilter do
  subject(:filter) { described_class.new(config, bug_data) }

  let(:config) { {} }
  let(:bug_data) { {} }

  context 'when the product matches the filter' do
    let(:bug_data) { { 'product' => 'TestProduct' } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns true' do
      expect(filter.by_product).to be(true)
    end
  end

  context 'when the product does not match the filter' do
    let(:bug_data) { { 'product' => 'AnotherProduct' } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns false' do
      expect(filter.by_product).to be(false)
    end
  end

  context 'when no products are specified in the config' do
    let(:bug_data) { { 'product' => 'TestProduct' } }
    let(:config) { {} }

    it 'returns true' do
      expect(filter.by_product).to be(true)
    end
  end

  context 'when the bug has no product' do
    let(:bug_data) { { 'product' => nil } }
    let(:config) { { 'products' => ['TestProduct'] } }

    it 'returns true' do
      expect(filter.by_product).to be(true)
    end
  end
end
