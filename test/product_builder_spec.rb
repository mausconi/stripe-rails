require 'spec_helper'

describe 'building products' do
  before do
    Stripe.product :primo do |product|
      product.name = 'Acme as a service PRIMO'
      product.type = 'service'
    end
  end

  after { Stripe::Products.send(:remove_const, :PRIMO) }

  it 'is accessible via id' do
    Stripe::Products::PRIMO.wont_be_nil
  end

  it 'is accessible via collection' do
    Stripe::Products.all.must_include Stripe::Products::PRIMO
  end

  it 'is accessible via hash lookup (symbol/string agnostic)' do
    Stripe::Products[:primo].must_equal  Stripe::Products::PRIMO
    Stripe::Products['primo'].must_equal Stripe::Products::PRIMO
  end

  describe '.put!' do
    describe 'when none exists on stripe.com' do
      before { Stripe::Product.stubs(:retrieve).raises(Stripe::InvalidRequestError.new("not found", "id")) }

      it 'creates the plan online' do
        Stripe::Product.expects(:create).with(
          :id => :primo,
          :name => 'Acme as a service PRIMO',
          :type => 'service',
        )
        Stripe::Products::PRIMO.put!
      end
    end

    describe 'when it is already present on stripe.com' do
      before do
        Stripe::Product.stubs(:retrieve).returns(Stripe::Product.construct_from({
          :id => :primo,
          :name => 'Acme as a service PRIMO',
        }))
      end

      it 'is a no-op' do
        Stripe::Product.expects(:create).never
        Stripe::Products::PRIMO.put!
      end
    end
  end

  describe 'validations' do
    describe 'with missing mandatory values' do
      it 'raises an exception after configuring it' do
        lambda { Stripe.product(:bad){} }.must_raise Stripe::InvalidConfigurationError
      end
    end

    describe 'invalid type' do
      it 'raises an exception during configuration' do
        lambda {
          Stripe.product :broken do |plan|
            plan.name = 'Acme as a service BROKEN'
            plan.type = 'anything'
          end
        }.must_raise Stripe::InvalidConfigurationError
      end
    end
  end
end
