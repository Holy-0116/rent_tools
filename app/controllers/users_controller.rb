class UsersController < ApplicationController
  before_action :login_user?
  before_action :correct_user?
  before_action :user_params, only: [:update]
  

  def show
    @user = User.find_by(id: params[:id])
  end
  def edit
    @user = User.find_by(id: params[:id])
  end

  def update
    if current_user.update(user_params)
      redirect_to root_path
    else
      @user = User.find_by(id: params[:id])
      render :show
    end
  end

  private

  def login_user?
    unless current_user
      redirect_to root_path
    end
  end

  def correct_user?
    @user = User.find_by(id: params[:id])
    unless @user == current_user
      redirect_to root_path
    end
  end

  def user_params
    params.require(:user).permit( :email, :company_name)
  end


end
