class OrdersController < ApplicationController
  before_action :set_user
  before_action :set_item
  before_action :set_api_key, only: [:select_card, :set_default_card, :create_card, :create]
  before_action :get_cards, only: [:select_card, :set_default_card]

  def new
    
    @order = Order.new
  end

  def create
    if current_user.address == nil
      render :new
      return
    end
    if params[:order][:price] != nil && params[:order][:price] != ""
      charge_create
    else
      redirect_to new_item_order_path
      return
    end
    
      @order = Order.new(order_params)
      if @order.valid?
        @order.save
        stock = (@item.stock.to_i) - (order_params[:piece].to_i)
        @item.update(stock: stock)
        redirect_to root_path
        OrderMailer.send_when_order_create(@order).deliver

      else
        redirect_to new_item_order_path
      end
  end

  def new_card
  end

  def create_card
     # card_tokenが正しいか確認
     if params[:card_token] == nil
      redirect_to select_card_item_order_path(@item)
      return
    end
    # ユーザーのcustomer_tokenが存在する場合
    if Card.find_by(user_id: current_user.id)
      card = current_user.card
      customer = Payjp::Customer.retrieve(card[0][:customer_token])
      customer.cards.create(
        card: params[:card_token]
      )
    else
    # ユーザーがcustomer_tokenが存在していない場合 
      customer = Payjp::Customer.create(
        description: "test",
        card: params[:card_token],)
    end
    # cardテーブルに保存
    card = Card.new(
      user_id: current_user.id,
      card_token: params[:card_token],
      customer_token: customer.id)
    if card.save
      redirect_to select_card_item_order_path(@item)
    else
      render select_card_item_order_path(@item)
    end
    
  end
  

  def select_card
    if current_user.card.present? 
      get_cards
    else
      return
    end
  end

  def set_default_card
    if current_user.card.present? 
      get_cards
    else
      render :select_card
      return
    end
    
    index = params[:selected].to_i
    @customer[:default_card] = @cards[0].data[index][:id]
    @customer.save
    redirect_to new_item_order_path
  end

  def new_address
    @address = Address.new
  end

  def set_address
    @item = Item.find_by(id: params[:item_id])
    @user = User.find_by(id: params[:user_id])
    @address = Address.new(address_params)
    if @address.valid?
      @address.save
      redirect_to new_item_order_path(@item)
    else
      render :new
    end
  end

  def edit_address
    @address = Address.find_by(user_id: current_user.id)
  end

  def update_address
    @item = Item.find_by(id: params[:item_id])
    @user = User.find_by(id: current_user.id)
    if @user.address.update(address_params)
      redirect_to new_item_order_path(@item)
    else
      render :new
    end
  end


  private
  
  def set_user
    @user = User.find_by(id: current_user.id)
  end

  def set_item
    @item = Item.find_by(id: params[:item_id])
  end

  def order_params
    params.require(:order).permit(:piece, :start_date, :return_date, :period, :price)
    .merge(item_id:params[:item_id],borrower_id: current_user.id, lender_id: Item.find_by(id:params[:item_id]).user_id)
  end

  def set_api_key
    Payjp.api_key = ENV["PAYJP_SECRET_KEY"]
  end

  def card_params
    params.permit(:card_token, :user_id)
  end

  def get_cards
    cards = Card.where(user_id: current_user.id)
      @cards = []
      cards.each do |card|
        @customer = Payjp::Customer.retrieve(card.customer_token)
        @cards << @customer.cards
      end
  end

  def charge_create
      Payjp.api_key = ENV["PAYJP_SECRET_KEY"]
      card = Card.find_by(user_id: current_user.id)
      customer = Payjp::Customer.retrieve(card.customer_token)
      Payjp::Charge.create(
        :amount => params[:order][:price],
        :customer => customer.id,
        :currency => 'jpy')         
  end

  def address_params
    params.require(:address).permit(:postal_code, :prefecture_id, :city_name, :house_number, :building_name, :phone_number).merge(user_id: current_user.id)
  end
end