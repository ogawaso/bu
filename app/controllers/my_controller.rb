# coding: utf-8
class MyController < ApplicationController
  before_filter :login_required
  helper_method :current_user

  def show
    @groups = @user.groups
    @events = @groups.map(&:events).flatten.sort_by(&:started_at).reverse
  end

  # GET /users/edit
  def edit
    current_user.locale = session[:language]
  end

  # PUT /users/1
  def update
    if @user.update_attributes(params[:user])
      session[:language] = @user.locale #TODO 仕様を決める
      redirect_to my_url, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  private
  def current_user #TODO 認証関連の再設計時にリファクタリングすること
    @user
  end
end
